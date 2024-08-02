defmodule Pears.Core.Team do
  use OpenTelemetryDecorator

  @derive {O11y.SpanAttributes, only: [:id, :name, :slack_channel]}
  defstruct name: nil,
            id: nil,
            slack_channel: nil,
            slack_token: nil,
            available_pears: %{},
            assigned_pears: %{},
            tracks: %{},
            history: []

  alias Pears.Core.AvailablePears
  alias Pears.Core.Pear
  alias Pears.Core.Track

  @decorate trace("team.new", include: [:team, :fields])
  def new(fields) do
    team = struct!(__MODULE__, fields)
    Map.put(team, :id, team.name)
  end

  @decorate trace("team.add_pear", include: [:team, :pear_name, :params])
  def add_pear(team, pear_name, params \\ []) do
    pear = Pear.new(Keyword.merge(params, name: pear_name))
    updated_available_pears = AvailablePears.add_pear(team.available_pears, pear)
    Map.put(team, :available_pears, updated_available_pears)
  end

  @decorate trace("team.update_pear", include: [:team, :pear_name, :params])
  def update_pear(team, pear_name, params \\ []) do
    assigned_pear = find_assigned_pear(team, pear_name)
    available_pear = find_available_pear(team, pear_name)

    cond do
      assigned_pear != nil ->
        updated_pear = Pear.update(assigned_pear, params)
        assigned_pears = Map.put(team.assigned_pears, pear_name, updated_pear)

        track = Map.get(team.tracks, updated_pear.track)
        updated_pears = Map.put(track.pears, pear_name, updated_pear)
        updated_track = Map.put(track, :pears, updated_pears)
        updated_tracks = Map.put(team.tracks, updated_pear.track, updated_track)

        team
        |> Map.put(:assigned_pears, assigned_pears)
        |> Map.put(:tracks, updated_tracks)

      available_pear != nil ->
        updated_pear = Pear.update(available_pear, params)
        available_pears = Map.put(team.available_pears, pear_name, updated_pear)
        updated_team = Map.put(team, :available_pears, available_pears)
        updated_team
    end
  end

  @decorate trace("team.remove_pear", include: [:team, :pear_name])
  def remove_pear(team, pear_name) do
    pear = find_pear(team, pear_name)

    if pear.track == nil do
      remove_available_pear(team, pear)
    else
      remove_assigned_pear(team, pear)
    end
  end

  defp remove_available_pear(team, pear) do
    Map.put(team, :available_pears, Map.delete(team.available_pears, pear.name))
  end

  defp remove_assigned_pear(team, pear) do
    team
    |> remove_pear_from_track(pear.name, pear.track)
    |> remove_available_pear(pear)
  end

  @decorate trace("team.add_track", include: [:team, :track_name, :track])
  def add_track(team, track_name, track_id \\ nil) do
    track_id = track_id || next_track_id(team)
    track = Track.new(name: track_name, id: track_id)
    Map.put(team, :tracks, Map.put(team.tracks, track_name, track))
  end

  @decorate trace("team.remove_track", include: [:team, :track_name, :track])
  def remove_track(team, track_name) do
    track = find_track(team, track_name)

    team
    |> Map.put(:available_pears, AvailablePears.add_pears(team.available_pears, track.pears))
    |> Map.put(:tracks, Map.delete(team.tracks, track_name))
  end

  @decorate trace("team.lock_track", include: [:team, :track_name, :track])
  def lock_track(team, track_name) do
    track = find_track(team, track_name)
    updated_tracks = Map.put(team.tracks, track_name, Track.lock_track(track))
    Map.put(team, :tracks, updated_tracks)
  end

  @decorate trace("team.unlock_track", include: [:team, :track_name, :track])
  def unlock_track(team, track_name) do
    track = find_track(team, track_name)
    updated_tracks = Map.put(team.tracks, track_name, Track.unlock_track(track))
    Map.put(team, :tracks, updated_tracks)
  end

  @decorate trace(
              "team.rename_track",
              include: [
                :team,
                :track_name,
                :new_track_name,
                :track,
                :updated_assigned_pears,
                :updated_tracks
              ]
            )
  def rename_track(team, track_name, new_track_name) do
    track = find_track(team, track_name)

    updated_assigned_pears =
      team.assigned_pears
      |> Enum.map(fn
        {pear_name, %{track: ^track_name} = pear} ->
          {pear_name, Map.put(pear, :track, new_track_name)}

        pear ->
          pear
      end)
      |> Enum.into(%{})

    updated_tracks =
      team.tracks
      |> Map.delete(track_name)
      |> Map.put(new_track_name, Track.rename_track(track, new_track_name))

    team
    |> Map.put(:tracks, updated_tracks)
    |> Map.put(:assigned_pears, updated_assigned_pears)
  end

  @decorate trace(
              "team.add_pear_to_track",
              include: [
                :team,
                :pear_name,
                :track_name,
                :pear,
                :track,
                :updated_tracks,
                :updated_available_pears,
                :updated_assigned_pears
              ]
            )
  def add_pear_to_track(team, pear_name, track_name) do
    track = find_track(team, track_name)
    pear = find_available_pear(team, pear_name)

    updated_tracks = Map.put(team.tracks, track_name, Track.add_pear(track, pear))
    updated_available_pears = Map.delete(team.available_pears, pear_name)

    updated_assigned_pears = Map.put(team.assigned_pears, pear_name, Pear.add_track(pear, track))

    %{
      team
      | tracks: updated_tracks,
        available_pears: updated_available_pears,
        assigned_pears: updated_assigned_pears
    }
  end

  @decorate trace(
              "team.move_pear_to_track",
              include: [:team, :pear_name, :from_track_name, :to_track_name]
            )
  def move_pear_to_track(team, pear_name, from_track_name, to_track_name) do
    team
    |> remove_pear_from_track(pear_name, from_track_name)
    |> add_pear_to_track(pear_name, to_track_name)
  end

  @decorate trace(
              "team.remove_pear_from_track",
              include: [
                :team,
                :pear_name,
                :track_name,
                :track,
                :pears,
                :updated_tracks,
                :updated_available_pears,
                :updated_assigned_pears
              ]
            )
  def remove_pear_from_track(team, pear_name, track_name) do
    track = find_track(team, track_name)

    pear =
      team
      |> find_assigned_pear(pear_name)
      |> Pear.remove_track()

    updated_tracks = Map.put(team.tracks, track_name, Track.remove_pear(track, pear_name))
    updated_available_pears = AvailablePears.add_pear(team.available_pears, pear)
    updated_assigned_pears = Map.delete(team.assigned_pears, pear_name)

    %{
      team
      | tracks: updated_tracks,
        available_pears: updated_available_pears,
        assigned_pears: updated_assigned_pears
    }
  end

  @decorate trace("team.choose_anchors", include: [:team, :updated_tracks])
  def choose_anchors(team) do
    O11y.set_attributes(tracks: team.tracks)

    updated_tracks =
      team.tracks
      |> Enum.map(fn {name, track} -> {name, Track.choose_anchor(track)} end)
      |> Enum.into(%{})

    %{team | tracks: updated_tracks}
  end

  @decorate trace(
              "team.toggle_anchor",
              include: [:team, :pear_name, :track_name, :track, :updated_tracks]
            )
  def toggle_anchor(team, pear_name, track_name) do
    track = find_track(team, track_name)
    updated_tracks = Map.put(team.tracks, track_name, Track.toggle_anchor(track, pear_name))
    %{team | tracks: updated_tracks}
  end

  @decorate trace("team.anchors", include: [:team, :result])
  def anchors(team) do
    team
    |> Map.get(:tracks)
    |> Map.values()
    |> Enum.map(fn track -> {Map.get(track, :anchor), Map.get(track, :name)} end)
    |> Enum.filter(fn {anchor, _} -> anchor == nil end)
  end

  @decorate trace("team.record_pears", include: [:team])
  def record_pears(team) do
    if any_pears_assigned?(team) do
      %{team | history: [current_matches(team)] ++ team.history}
    else
      team
    end
  end

  @decorate trace("team.find_track", include: [:team, :track_name])
  def find_track(team, track_name), do: Map.get(team.tracks, track_name, nil)

  @decorate trace("team.find_pear", include: [:team, :pear_name])
  def find_pear(team, pear_name) do
    find_available_pear(team, pear_name) || find_assigned_pear(team, pear_name)
  end

  @decorate trace("team.find_available_pear", include: [:team, :pear_name])
  def find_available_pear(team, pear_name), do: Map.get(team.available_pears, pear_name, nil)

  @decorate trace("team.find_assigned_pear", include: [:team, :pear_name])
  def find_assigned_pear(team, pear_name), do: Map.get(team.assigned_pears, pear_name, nil)

  @decorate trace("team.match_in_history?", include: [:team, :potential_match])
  def match_in_history?(team, potential_match) do
    Enum.any?(team.history, fn days_matches ->
      matched_on_day?(days_matches, potential_match, team)
    end)
  end

  @decorate trace("team.matched_yesterday?", include: [[:_team, :name], :potential_match])
  def matched_yesterday?(%{history: []} = _team, _), do: false

  @decorate trace("team.matched_yesterday?", include: [:team, :potential_match])
  def matched_yesterday?(team, potential_match) do
    team.history
    |> List.first()
    |> matched_on_day?(potential_match, team)
  end

  @decorate trace("team.set_slack_channel", include: [:team, :slack_channel])
  def set_slack_channel(team, slack_channel) do
    Map.put(team, :slack_channel, slack_channel)
  end

  @decorate trace("team.set_slack_token", include: [:team])
  def set_slack_token(team, slack_token) do
    Map.put(team, :slack_token, slack_token)
  end

  @decorate trace("team.matched_on_day?",
              include: [:days_matches, :potential_match, [:_team, :name]]
            )
  defp matched_on_day?(days_matches, potential_match, _team) do
    days_matches
    |> Enum.any?(fn {_, match} ->
      Enum.all?(potential_match, fn pear ->
        Enum.count(match) < 4 && Enum.member?(match, pear)
      end)
    end)
  end

  @decorate trace("team.available_slot_count", include: [:team])
  def available_slot_count(team) do
    team.tracks
    |> Map.values()
    |> Enum.reduce(0, fn track, count ->
      cond do
        Track.locked?(track) -> count
        Track.incomplete?(track) -> count + 1
        Track.empty?(track) -> count + 2
        true -> count
      end
    end)
  end

  @decorate trace("team.rotatable_tracks", include: [:team])
  def rotatable_tracks(team) do
    team.tracks
    |> Map.values()
    |> Enum.reject(&Track.incomplete?/1)
    |> Enum.reject(&Track.locked?/1)
  end

  @decorate trace("team.potential_matches", include: [:team])
  def potential_matches(team) do
    assigned =
      team.tracks
      |> Map.values()
      |> Enum.filter(&Track.incomplete?/1)
      |> Enum.reject(&Track.locked?/1)
      |> Enum.flat_map(fn track -> Map.keys(track.pears) end)

    available = Map.keys(team.available_pears)

    %{available: available, assigned: assigned}
  end

  @decorate trace("team.current_matches", include: [:team])
  def current_matches(team) do
    team.tracks
    |> Enum.map(fn {track_name, track} ->
      {track_name, Enum.map(track.pears, fn {name, _} -> name end)}
    end)
  end

  @decorate trace("team.historical_matches", include: [:team])
  def historical_matches(team) do
    Enum.map(team.history, fn days_matches ->
      Enum.map(days_matches, fn {_, match} -> List.to_tuple(match) end)
    end)
  end

  @decorate trace("team.reset_matches", include: [:team])
  def reset_matches(team) do
    team.tracks
    |> Map.values()
    |> Enum.reject(&Track.locked?/1)
    |> Enum.flat_map(fn track ->
      track.pears
      |> Map.values()
      |> Enum.reject(fn pear -> pear.name == track.anchor end)
      |> Enum.map(&Map.put(&1, :track, track.name))
    end)
    |> Enum.reduce(team, fn pear, team ->
      remove_pear_from_track(team, pear.name, pear.track)
    end)
  end

  @decorate trace("team.assign_pears_from_history", include: [:team])
  def assign_pears_from_history(team) do
    team.history
    |> List.first()
    |> Enum.reduce(team, fn {track, pears}, team ->
      Enum.reduce(pears, team, fn pear, team ->
        add_pear_to_track(team, pear, track)
      end)
    end)
  end

  @decorate trace("team.any_pears_assigned?", include: [:team, :result])
  def any_pears_assigned?(team), do: Enum.any?(team.assigned_pears)

  @decorate trace("team.any_pears_available?", include: [:team, :result])
  def any_pears_available?(team), do: Enum.any?(team.available_pears)

  @decorate trace("team.pear_available?", include: [:team, :pear_name, :result])
  def pear_available?(team, pear_name), do: Map.has_key?(team.available_pears, pear_name)

  @decorate trace("team.pear_assigned?", include: [:team, :pear_name, :result])
  def pear_assigned?(team, pear_name), do: Map.has_key?(team.assigned_pears, pear_name)

  @decorate trace("team.find_empty_track", include: [:team, :track])
  def find_empty_track(team) do
    {_, track} =
      Enum.find(team.tracks, {nil, nil}, fn {_name, track} ->
        Track.empty?(track) && Track.unlocked?(track)
      end)

    track
  end

  @decorate trace("team.facilitator", include: [:team, :result])
  def facilitator(team) do
    team
    |> active_pears()
    |> random_or_nil()
  end

  @decorate trace("team.has_active_pears?", include: [:team, :result])
  def has_active_pears?(team) do
    team
    |> active_pears()
    |> Enum.any?()
  end

  @doc """
  Returns the difference in hours between two pears' timezone offsets.
  """
  @spec timezone_difference(Pear.t(), Pear.t()) :: integer
  @decorate with_span("team.timezone_difference")
  def timezone_difference(%{timezone_offset: nil}, _), do: 0
  def timezone_difference(_, %{timezone_offset: nil}), do: 0

  def timezone_difference(pear1, pear2) do
    difference_seconds = abs(pear1.timezone_offset - pear2.timezone_offset)
    difference_hours = div(difference_seconds, 3600)

    O11y.set_attributes(
      left: pear1.timezone_offset,
      right: pear2.timezone_offset,
      difference_hours: difference_hours,
      difference_seconds: difference_seconds
    )

    difference_hours
  end

  @spec misaligned_tz_matches(Team.t()) :: [Pear.t()]
  @decorate with_span("team.misaligned_tz_matches")
  def misaligned_tz_matches(team) do
    team.tracks
    |> Enum.map(fn {_track_name, track} ->
      pears = Map.values(track.pears)
      if significant_tz_differences?(pears), do: pears, else: []
    end)
    |> Enum.reject(&Enum.empty?/1)
    |> tap(fn matches ->
      Enum.map(matches, fn match ->
        O11y.add_event("misaligned_tz_match", %{match: match})
      end)
    end)
  end

  def metadata(team) do
    current_matches =
      team
      |> current_matches()
      |> Enum.into(%{})

    recent_history =
      team.history
      |> Enum.take(5)
      |> Enum.with_index()
      |> Enum.map(fn {matches, index} -> {index, Enum.into(matches, %{})} end)
      |> Enum.into(%{})

    %{
      team_name: team.name,
      available_pears: Map.keys(team.available_pears),
      current_matches: current_matches,
      recent_history: recent_history
    }
  end

  defp timezone_differences(pears) do
    for pear1 <- pears, pear2 <- pears do
      timezone_difference(pear1, pear2)
    end
  end

  defp significant_tz_differences?(pears) do
    pears
    |> timezone_differences()
    |> Enum.any?(&(&1 > 1))
  end

  defp random_or_nil([]), do: nil
  defp random_or_nil(list), do: Enum.random(list)

  defp active_pears(team) do
    team.available_pears
    |> Map.merge(team.assigned_pears)
    |> Map.values()
  end

  @decorate trace("team.next_track_id", include: [:team])
  defp next_track_id(team), do: Enum.count(team.tracks) + 1
end
