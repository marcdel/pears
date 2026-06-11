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
    |> assign_pears()
    |> Team.clear_anchors(auto_anchored_tracks)
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
  defp potential_matches_by_score(team) do
    potential_matches = Team.potential_matches(team)

    primary =
      potential_matches
      |> primary_matches()
      |> score_matches(team)

    secondary =
      potential_matches
      |> secondary_matches()
      |> score_matches(team)

    scored_matches = sort_scored_matches(primary, secondary, team)
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

  defp sort_scored_matches(primary, secondary, team) do
    splitter = fn {_, score} -> score >= max_score(team) end

    {p1, p3} = Enum.split_with(primary, splitter)
    {p2, p4} = Enum.split_with(secondary, splitter)

    [p1, p2, p3, p4]
    |> Enum.concat()
    |> Enum.map(fn {match, _} -> match end)
  end

  defp score_matches(potential_matches, team) do
    indexed_history =
      team
      |> Team.historical_matches()
      |> Enum.with_index(1)

    potential_matches
    |> Enum.map(fn {p1, p2} ->
      {_, score} =
        Enum.find(indexed_history, {[], max_score(team)}, fn {days_matches, _index} ->
          Enum.member?(days_matches, {p1, p2}) || Enum.member?(days_matches, {p2, p1})
        end)

      {{p1, p2}, score}
    end)
    |> sort_by_score_shuffling_ties()
  end

  # Equally-scored matches used to keep map-iteration (alphabetical) order,
  # so identical boards always produced the identical suggestion and
  # alphabetically-early pears systematically won ties. Shuffling before the
  # stable sort randomizes order within each score group without disturbing
  # the score ordering itself.
  defp sort_by_score_shuffling_ties(scored_matches) do
    scored_matches
    |> Enum.shuffle()
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
  end
end
