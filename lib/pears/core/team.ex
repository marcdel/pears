defmodule Pears.Core.Team do
  defstruct name: nil, pears: [], tracks: []

  alias Pears.Core.Track

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(team, pear) do
    Map.put(team, :pears, [pear] ++ team.pears)
  end

  def add_track(team, track) do
    Map.put(team, :tracks, [track] ++ team.tracks)
  end

  def remove_track(team, track_name) do
    Map.put(
      team,
      :tracks,
      Enum.filter(team.tracks, fn track ->
        track.name == track_name
      end)
    )
  end

  def add_to_track(team, pear_name, track_name) do
    updated_tracks =
      Enum.map(team.tracks, fn
        %{name: ^track_name} = track ->
          pear = find_pear(team, pear_name)
          Track.add_pear(track, pear)

        track ->
          track
      end)

    Map.put(team, :tracks, updated_tracks)
  end

  def remove_from_track(team, pear_name, track_name) do
    updated_tracks =
      Enum.map(team.tracks, fn
        %{name: ^track_name} = track -> Track.remove_pear(track, pear_name)
        track -> track
      end)

    Map.put(team, :tracks, updated_tracks)
  end

  def find_track(team, track_name) do
    Enum.find(team.tracks, fn track -> track.name == track_name end)
  end

  def find_pear(team, pear_name) do
    Enum.find(team.pears, fn pear -> pear.name == pear_name end)
  end
end
