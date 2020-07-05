defmodule Pears.Core.Team do
  defstruct name: nil, pears: [], tracks: []

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(team, pear) do
    Map.put(team, :pears, [pear] ++ team.pears)
  end

  def add_track(team, track) do
    Map.put(team, :tracks, [track] ++ team.tracks)
  end
end
