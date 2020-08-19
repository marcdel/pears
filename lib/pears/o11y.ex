defmodule Pears.O11y do
  alias Pears.O11y.Tracer

  def recommend_pears(team_name, callback) do
    event_name = [:pears, :recommend_pears]
    metadata = %{team_name: team_name}

    Tracer.trace(event_name, metadata, callback)
  end
end
