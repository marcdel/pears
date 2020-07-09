defmodule Pears.Core.Recommendator do
  alias Pears.Core.Team

  def assign_pears(team) do
    Enum.reduce(team.available_pears, team, &assign_pear/2)
  end

  defp assign_pear({pear_name, pear}, team) do
    {track_name, track} = find_available_track(team)
    Team.add_to_track(team, pear_name, track_name)
  end

  defp find_available_track(team) do
    Enum.find(team.tracks, fn {_name, track} -> Enum.count(track.pears) == 0 end)
  end
end
