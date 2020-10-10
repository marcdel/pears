defmodule Pears.Core.Team do
  use OpenTelemetryDecorator

  defstruct name: nil,
            id: nil,
            available_pears: %{},
            assigned_pears: %{},
            tracks: %{},
            history: []

  alias Pears.Core.AvailablePears
  alias Pears.Core.Pear
  alias Pears.Core.Track

  @decorate trace("team.new", include: [[:team, :name], :fields])
  def new(fields) do
    team = struct!(__MODULE__, fields)
    Map.put(team, :id, team.name)
  end

  @decorate trace("team.add_pear", include: [[:team, :name], :pear_name])
  def add_pear(team, pear_name, pear_id \\ nil) do
    pear = Pear.new(name: pear_name, id: pear_id)
    updated_available_pears = AvailablePears.add_pear(team.available_pears, pear)
    Map.put(team, :available_pears, updated_available_pears)
  end

  @decorate trace("team.remove_pear", include: [[:team, :name], :pear_name])
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

  @decorate trace("team.add_track", include: [[:team, :name], :track_name, :track])
  def add_track(team, track_name, track_id \\ nil) do
    track_id = track_id || next_track_id(team)
    track = Track.new(name: track_name, id: track_id)
    Map.put(team, :tracks, Map.put(team.tracks, track_name, track))
  end

  @decorate trace("team.remove_track", include: [[:team, :name], :track_name, :track])
  def remove_track(team, track_name) do
    track = find_track(team, track_name)

    team
    |> Map.put(:available_pears, AvailablePears.add_pears(team.available_pears, track.pears))
    |> Map.put(:tracks, Map.delete(team.tracks, track_name))
  end

  @decorate trace("team.lock_track", include: [[:team, :name], :track_name, :track])
  def lock_track(team, track_name) do
    track = find_track(team, track_name)
    updated_tracks = Map.put(team.tracks, track_name, Track.lock_track(track))
    Map.put(team, :tracks, updated_tracks)
  end

  @decorate trace("team.unlock_track", include: [[:team, :name], :track_name, :track])
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

  @decorate trace("team.record_pears", include: [[:team, :name]])
  def record_pears(team) do
    if any_pears_assigned?(team) do
      %{team | history: [current_matches(team)] ++ team.history}
    else
      team
    end
  end

  @decorate trace("team.find_track", include: [[:team, :name], :track_name])
  def find_track(team, track_name), do: Map.get(team.tracks, track_name, nil)

  @decorate trace("team.find_pear", include: [[:team, :name], :pear_name])
  def find_pear(team, pear_name) do
    find_available_pear(team, pear_name) || find_assigned_pear(team, pear_name)
  end

  @decorate trace("team.find_available_pear", include: [[:team, :name], :pear_name])
  def find_available_pear(team, pear_name), do: Map.get(team.available_pears, pear_name, nil)

  @decorate trace("team.find_assigned_pear", include: [[:team, :name], :pear_name])
  def find_assigned_pear(team, pear_name), do: Map.get(team.assigned_pears, pear_name, nil)

  @decorate trace("team.match_in_history?", include: [[:team, :name], :potential_match])
  def match_in_history?(team, potential_match) do
    Enum.any?(team.history, fn days_matches ->
      matched_on_day?(days_matches, potential_match, team)
    end)
  end

  @decorate trace("team.matched_yesterday?", include: [[:_team, :name], :potential_match])
  def matched_yesterday?(%{history: []} = _team, _), do: false

  @decorate trace("team.matched_yesterday?", include: [[:team, :name], :potential_match])
  def matched_yesterday?(team, potential_match) do
    team.history
    |> List.first()
    |> matched_on_day?(potential_match, team)
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

  @decorate trace("team.available_slot_count", include: [[:team, :name]])
  def available_slot_count(team) do
    team.tracks
    |> Map.values()
    |> Enum.reduce(0, fn track, count ->
      cond do
        Track.incomplete?(track) -> count + 1
        Track.empty?(track) -> count + 2
        true -> count
      end
    end)
  end

  @decorate trace("team.potential_matches", include: [[:team, :name]])
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

  @decorate trace("team.current_matches", include: [[:team, :name]])
  def current_matches(team) do
    team.tracks
    |> Enum.map(fn {track_name, track} ->
      {track_name, Enum.map(track.pears, fn {name, _} -> name end)}
    end)
  end

  @decorate trace("team.historical_matches", include: [[:team, :name]])
  def historical_matches(team) do
    Enum.map(team.history, fn days_matches ->
      Enum.map(days_matches, fn {_, match} -> List.to_tuple(match) end)
    end)
  end

  @decorate trace("team.reset_matches", include: [[:team, :name]])
  def reset_matches(team) do
    team.tracks
    |> Map.values()
    |> Enum.reject(&Track.locked?/1)
    |> Enum.flat_map(fn track ->
      track.pears
      |> Map.values()
      |> Enum.map(&Map.put(&1, :track, track.name))
    end)
    |> Enum.reduce(team, fn pear, team ->
      remove_pear_from_track(team, pear.name, pear.track)
    end)
  end

  @decorate trace("team.assign_pears_from_history", include: [[:team, :name]])
  def assign_pears_from_history(team) do
    team.history
    |> List.first()
    |> Enum.reduce(team, fn {track, pears}, team ->
      Enum.reduce(pears, team, fn pear, team ->
        add_pear_to_track(team, pear, track)
      end)
    end)
  end

  @decorate trace("team.any_pears_assigned?", include: [[:team, :name]])
  def any_pears_assigned?(team), do: Enum.any?(team.assigned_pears)

  @decorate trace("team.any_pears_available?", include: [[:team, :name]])
  def any_pears_available?(team), do: Enum.any?(team.available_pears)

  @decorate trace("team.pear_available?", include: [[:team, :name], :pear_name])
  def pear_available?(team, pear_name), do: Map.has_key?(team.available_pears, pear_name)

  @decorate trace("team.pear_assigned?", include: [[:team, :name], :pear_name])
  def pear_assigned?(team, pear_name), do: Map.has_key?(team.assigned_pears, pear_name)

  @decorate trace("team.find_empty_track", include: [[:team, :name], :track])
  def find_empty_track(team) do
    {_, track} = Enum.find(team.tracks, {nil, nil}, fn {_name, track} -> Track.empty?(track) end)
    track
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

  @decorate trace("team.next_track_id", include: [[:team, :name]])
  defp next_track_id(team), do: Enum.count(team.tracks) + 1
end
