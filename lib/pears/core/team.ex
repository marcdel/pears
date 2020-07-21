defmodule Pears.Core.Team do
  defstruct name: nil, id: nil, available_pears: %{}, tracks: %{}, history: []

  alias Pears.Core.{Pear, Track}

  def new(fields) do
    team = struct!(__MODULE__, fields)
    Map.put(team, :id, to_slug(team))
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
    updated_pears = Map.delete(team.available_pears, pear_name)

    %{team | tracks: updated_tracks, available_pears: updated_pears}
  end

  def move_pear_to_track(team, pear_name, from_track_name, to_track_name) do
    team
    |> remove_pear_from_track(pear_name, from_track_name)
    |> add_pear_to_track(pear_name, to_track_name)
  end

  def remove_pear_from_track(team, pear_name, track_name) do
    track = find_track(team, track_name)
    pear = Track.find_pear(track, pear_name)

    updated_tracks = Map.put(team.tracks, track_name, Track.remove_pear(track, pear_name))
    updated_pears = Map.put(team.available_pears, pear_name, pear)

    %{team | tracks: updated_tracks, available_pears: updated_pears}
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

  def find_assigned_pear(team, pear_name) do
    assigned_pears(team)
    |> List.flatten()
    |> Enum.find(fn name -> name == pear_name end)
  end

  def assigned_pears(team) do
    team.tracks
    |> Enum.map(fn {_, track} ->
      Enum.map(track.pears, fn {name, _} -> name end)
    end)
  end

  def any_pears_assigned?(team) do
    team
    |> assigned_pears()
    |> List.flatten()
    |> Enum.any?()
  end

  def pear_available?(team, pear_name), do: Map.has_key?(team.available_pears, pear_name)

  defp to_slug(team), do: String.downcase(team.name) |> String.replace(" ", "-")

  defp next_track_id(team) do
    Enum.count(team.tracks) + 1
  end
end
