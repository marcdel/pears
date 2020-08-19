defmodule Pears.O11y.UI do
  alias Pears.Core.Team
  alias Pears.O11y.Tracer

  def recommend_pears(team, callback) do
    event_name = [:pears, :ui, :recommend_pears]
    metadata = %{team: Team.metadata(team)}

    Tracer.trace(event_name, metadata, callback)
  end
end
