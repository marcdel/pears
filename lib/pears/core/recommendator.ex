defmodule Pears.Core.Recommendator do
  use OpenTelemetryDecorator

  alias Pears.Core.{MatchValidator, Team}

  @decorate trace("recommendator.choose_anchors_and_suggest", include: [:team])
  def choose_anchors_and_suggest(team) do
    # Tracks without a user-set anchor get a temporary one so somebody stays
    # behind during the reset; those temporary anchors are cleared again at
    # the end so only user-set anchors survive a suggestion.
    auto_anchored_tracks = Team.unanchored_track_names(team)

    team
    |> Team.choose_anchors()
    |> Team.reset_matches()
    |> add_tracks_for_unseated_pears()
    |> assign_pears()
    |> Team.clear_anchors(auto_anchored_tracks)
  end

  # Counted after the reset: the bench now holds the freed pears too, and a
  # track that had three pears exposes only one slot (its anchor stays), so
  # counting beforehand under-provisions and leaves someone benched.
  @decorate trace("recommendator.add_tracks_for_unseated_pears", include: [:team])
  defp add_tracks_for_unseated_pears(team) do
    unseated = Enum.count(team.available_pears) - Team.available_slot_count(team)
    tracks_needed = ceil(unseated / 2)

    if tracks_needed > 0 do
      Enum.reduce(1..tracks_needed, team, fn _, team ->
        Team.add_track(team, next_untitled_track_name(team))
      end)
    else
      team
    end
  end

  # "Untitled Track #{n}" for the smallest n not already taken, so suggesting
  # keeps working on boards that already have untitled tracks from earlier
  # suggestions.
  defp next_untitled_track_name(team) do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"Untitled Track #{&1}")
    |> Enum.find(&(not Map.has_key?(team.tracks, &1)))
  end

  @decorate trace("recommendator.assign_pears", include: [:team])
  def assign_pears(team) do
    team
    |> potential_matches_by_score()
    |> assign_matches(team)
  end

  @decorate trace("recommendator.assign_matches", include: [:team, :potential_matches])
  defp assign_matches(potential_matches, team) do
    Enum.reduce_while(potential_matches, team, fn match, team ->
      if Team.any_pears_available?(team) do
        {:cont, assign_match(match, team)}
      else
        {:halt, team}
      end
    end)
  end

  @decorate trace("recommendator.assign_match", include: [:team, :match])
  def assign_match(match, team) do
    if MatchValidator.valid?(match, team), do: do_assign_match(match, team), else: team
  end

  @decorate trace("recommendator.do_assign_match", include: [:team, :p1, :empty_track])
  defp do_assign_match({p1}, team) do
    empty_track = Team.find_empty_track(team)
    Team.add_pear_to_track(team, p1, empty_track.name)
  end

  @decorate trace(
              "recommendator.do_assign_match",
              include: [:team, :p1, :pear1, :p2, :pear2, :empty_track]
            )
  defp do_assign_match({p1, p2}, team) do
    pear1 = Team.find_pear(team, p1)
    pear2 = Team.find_pear(team, p2)

    cond do
      Team.pear_available?(team, p1) && Team.pear_available?(team, p2) ->
        empty_track = Team.find_empty_track(team)

        team
        |> Team.add_pear_to_track(p1, empty_track.name)
        |> Team.add_pear_to_track(p2, empty_track.name)

      Team.pear_available?(team, p1) ->
        Team.add_pear_to_track(team, p1, pear2.track)

      Team.pear_available?(team, p2) ->
        Team.add_pear_to_track(team, p2, pear1.track)

      true ->
        team
    end
  end

  @decorate trace(
              "recommendator.potential_matches_by_score",
              include: [
                :team,
                :potential_matches,
                :primary,
                :secondary,
                :scored_matches,
                :solo_pears
              ]
            )
  # Matches are tried in this order: never-paired before previously-paired,
  # primary (bench + already-seated) before secondary (bench + bench) within
  # each, then by recency, longest-ago first. Shuffling first randomizes only
  # the order within those tie groups — the stable sort preserves everything
  # the policy cares about. Solo placements are the last resort.
  defp potential_matches_by_score(team) do
    potential_matches = Team.potential_matches(team)
    indexed_history = team |> Team.historical_matches() |> Enum.with_index(1)
    max_score = max_score(team)

    primary = Enum.map(primary_matches(potential_matches), &{&1, _primary? = true})
    secondary = Enum.map(secondary_matches(potential_matches), &{&1, _primary? = false})

    scored_matches =
      (primary ++ secondary)
      |> Enum.map(fn {match, primary?} ->
        {match, primary?, score(match, indexed_history, max_score)}
      end)
      |> Enum.shuffle()
      |> Enum.sort_by(
        fn {_match, primary?, score} -> {score >= max_score, primary?, score} end,
        :desc
      )
      |> Enum.map(fn {match, _primary?, _score} -> match end)

    solo_pears = Enum.map(potential_matches.available, fn pear -> {pear} end)

    scored_matches ++ solo_pears
  end

  defp primary_matches(potential_matches) do
    for p1 <- potential_matches.available,
        p2 <- potential_matches.assigned,
        p1 != p2,
        do: {p1, p2}
  end

  # Scoring is symmetric, so generating only one ordering of each available
  # pair halves the work. Assigning both pears of a match must happen in one
  # step (see the assign_match test) — there is no longer a reversed
  # duplicate later in the list to rescue a dropped pear.
  defp secondary_matches(potential_matches) do
    for p1 <- potential_matches.available,
        p2 <- potential_matches.available,
        p1 < p2,
        do: {p1, p2}
  end

  defp max_score(team), do: Enum.count(team.history) + 1

  # Scoring policy: a match scores by how long ago the two pears last worked
  # together — the 1-based index of the most recent history day containing
  # exactly that pair, or max_score (history length + 1) if they never have.
  # Recency is the whole policy; how *often* a pair has worked together is
  # deliberately ignored, so a pair that has paired many times but not lately
  # outranks a pair that paired once yesterday. Note that only exact pairs
  # register: a day spent together in a three-person track doesn't count as
  # having paired (see also the mob-day rule in Team.matched_on_day?/3).
  defp score({p1, p2}, indexed_history, max_score) do
    {_, score} =
      Enum.find(indexed_history, {nil, max_score}, fn {days_matches, _index} ->
        Enum.member?(days_matches, {p1, p2}) || Enum.member?(days_matches, {p2, p1})
      end)

    score
  end
end
