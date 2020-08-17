defmodule Pears.O11y.Team do
  alias Pears.O11y.Tracer

  def add_pear(team, pear_name, callback) do
    event_name = [:pears, :team, :add_pear]
    metadata = %{team_name: team.name, pear_name: pear_name}

    Tracer.trace(event_name, metadata, callback)
  end

  def add_pear_to_track(team, pear_name, track_name, callback) do
    event_name = [:pears, :team, :add_pear_to_track]
    metadata = %{team_name: team.name, pear_name: pear_name, track_name: track_name}

    Tracer.trace(event_name, metadata, callback)
  end
end
