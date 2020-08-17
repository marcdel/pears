defmodule Pears.O11y.Recommendator do
  alias Pears.O11y.Tracer

  def assign_pears(team, callback) do
    event_name = [:pears, :recommendator, :assign_pears]
    Tracer.trace_team_event(event_name: event_name, team: team, callback: callback)
  end
end
