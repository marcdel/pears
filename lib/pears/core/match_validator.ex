defmodule Pears.Core.MatchValidator do
  alias Pears.Core.{Team, Track}

  def valid?({p1}, team) do
    Team.pear_available?(team, p1) && Team.find_empty_track(team)
  end

  def valid?({p1, p2}, team) do
    valid =
      either_pear_available?({p1, p2}, team) &&
        destination_track_available?({p1, p2}, team)

    IO.inspect({p1, p2, valid})

    valid
  end

  defp either_pear_available?(match, team), do: available_pear(match, team) != nil

  defp destination_track_available?({p1, p2}, team) do
    track = destination_track({p1, p2}, team) || Team.find_empty_track(team)

    track && (Track.incomplete?(track) || Track.empty?(track))
  end

  defp available_pear({p1, p2}, team) do
    Team.find_available_pear(team, p1) ||
      Team.find_available_pear(team, p2)
  end

  defp destination_track({p1, p2}, team) do
    pear1 = Team.find_pear(team, p1)
    pear2 = Team.find_pear(team, p2)

    track = pear1.track || pear2.track
    track && Team.find_track(team, track)
  end
end
