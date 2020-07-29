defmodule Pears.Core.Team do
  defstruct name: nil,
            id: nil,
            available_pears: %{},
            assigned_pears: %{},
            tracks: %{},
            history: []

  alias Pears.Core.{Pear, Track}

  def new(fields) do
    team = struct!(__MODULE__, fields)
    Map.put(team, :id, team.name)
  end

  def add_pear(team, pear_name) do
    pear = Pear.new(name: pear_name)
    Map.put(team, :available_pears, Map.put(team.available_pears, pear_name, pear))
  end

  def remove_pear(team, pear_name) do
    Map.put(team, :available_pears, Map.delete(team.available_pears, pear_name))
  end

  def add_track(team, track_name) do
    track = Track.new(name: track_name, id: next_track_id(team))
    Map.put(team, :tracks, Map.put(team.tracks, track_name, track))
  end

  def remove_track(team, track_name) do
    track = find_track(team, track_name)

    team
    |> Map.put(:available_pears, Map.merge(team.available_pears, track.pears))
    |> Map.put(:tracks, Map.delete(team.tracks, track_name))
  end

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

  def move_pear_to_track(team, pear_name, from_track_name, to_track_name) do
    team
    |> remove_pear_from_track(pear_name, from_track_name)
    |> add_pear_to_track(pear_name, to_track_name)
  end

  def remove_pear_from_track(team, pear_name, track_name) do
    track = find_track(team, track_name)
    pear = find_assigned_pear(team, pear_name)

    updated_tracks = Map.put(team.tracks, track_name, Track.remove_pear(track, pear_name))
    updated_available_pears = Map.put(team.available_pears, pear_name, Pear.remove_track(pear))
    updated_assigned_pears = Map.delete(team.assigned_pears, pear_name)

    %{
      team
      | tracks: updated_tracks,
        available_pears: updated_available_pears,
        assigned_pears: updated_assigned_pears
    }
  end

  def record_pears(team) do
    if any_pears_assigned?(team) do
      %{team | history: [assigned_pears(team)] ++ team.history}
    else
      team
    end
  end

  def find_track(team, track_name), do: Map.get(team.tracks, track_name, nil)

  def find_available_pear(team, pear_name), do: Map.get(team.available_pears, pear_name, nil)
  def find_assigned_pear(team, pear_name), do: Map.get(team.assigned_pears, pear_name, nil)

  def where_is_pear?(team, pear_name) do
    assigned =
      team.tracks
      |> Enum.map(fn {_, track} ->
        Enum.map(track.pears, fn {_, pear} -> {pear, track} end)
      end)
      |> List.flatten()
      |> Enum.find(fn {pear, _} -> pear.name == pear_name end)

    available =
      team.available_pears
      |> Enum.map(fn {_, pear} -> pear end)
      |> Enum.find(fn pear -> pear.name == pear_name end)

    cond do
      assigned != nil ->
        {_, assigned_track} = assigned
        {:assigned, assigned_track}

      available != nil ->
        {:available, nil}

      true ->
        {:error, :not_found}
    end
  end

  def match_in_history?(team, potential_match) do
    Enum.flat_map(team.history, fn days_matches ->
      Enum.filter(days_matches, fn match ->
        Enum.sort(match) == Enum.sort(potential_match)
      end)
    end)
    |> Enum.any?()
  end

  def matched_yesterday?(%{history: []}, _), do: false

  def matched_yesterday?(%{history: history}, potential_match) do
    history
    |> List.first()
    |> Enum.any?(fn match -> Enum.sort(match) == Enum.sort(potential_match) end)
  end

  def assigned_pears(team) do
    team.tracks
    |> Enum.map(fn {_, track} ->
      Enum.map(track.pears, fn {name, _} -> name end)
    end)
  end

  def any_pears_assigned?(team), do: Enum.any?(team.assigned_pears)

  def pear_available?(team, pear_name), do: Map.has_key?(team.available_pears, pear_name)

  defp next_track_id(team) do
    Enum.count(team.tracks) + 1
  end
end
