defmodule Pears.Core.Team do
  defstruct name: nil, available_pears: %{}, tracks: %{}

  alias Pears.Core.{Pear, Track}

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(team, pear_name) do
    pear = Pear.new(name: pear_name)
    Map.put(team, :available_pears, Map.put(team.available_pears, pear_name, pear))
  end

  def remove_pear(team, pear_name) do
    Map.put(team, :available_pears, Map.delete(team.available_pears, pear_name))
  end

  def add_track(team, track_name) do
    track = Track.new(name: track_name)
    Map.put(team, :tracks, Map.put(team.tracks, track_name, track))
  end

  def remove_track(team, track_name) do
    Map.put(team, :tracks, Map.delete(team.tracks, track_name))
  end

  def add_to_track(team, pear_name, track_name) do
    track = find_track(team, track_name)
    pear = find_available_pear(team, pear_name)

    updated_tracks = Map.put(team.tracks, track_name, Track.add_pear(track, pear))
    updated_pears = Map.delete(team.available_pears, pear_name)

    %{team | tracks: updated_tracks, available_pears: updated_pears}
  end

  def remove_from_track(team, pear_name, track_name) do
    track = find_track(team, track_name)
    pear = Track.find_pear(track, pear_name)

    updated_tracks = Map.put(team.tracks, track_name, Track.remove_pear(track, pear_name))
    updated_pears = Map.put(team.available_pears, pear_name, Track.remove_pear(track, pear))

    %{team | tracks: updated_tracks, available_pears: updated_pears}
  end

  def find_track(team, track_name), do: Map.get(team.tracks, track_name, nil)

  def find_available_pear(team, pear_name), do: Map.get(team.available_pears, pear_name, nil)

  def pear_available?(team, pear_name), do: Map.has_key?(team.available_pears, pear_name)
end
