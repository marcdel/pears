defmodule Pears.Core.Recommendator do
  alias Pears.Core.Team

  def assign_pears(team) do
    Enum.reduce(team.available_pears, team, &assign_pear/2)
  end

  defp assign_pear({pear_name, _pear}, team) do
    case find_available_track(team) do
      {track_name, _track} -> Team.add_to_track(team, pear_name, track_name)
      :match_not_found -> team
    end
  end

  defp find_available_track(team) do
    find_incomplete_track(team) ||
      find_empty_track(team) ||
      :match_not_found
  end

  defp find_incomplete_track(team) do
    Enum.find(team.tracks, fn {_name, track} -> Enum.count(track.pears) == 1 end)
  end

  defp find_empty_track(team) do
    Enum.find(team.tracks, fn {_name, track} -> Enum.empty?(track.pears) end)
  end
end
