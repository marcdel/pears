defmodule Pears.O11y.Recommendator do
  alias Pears.O11y.Tracer
  alias Pears.Core.Team

  def assign_pears(team, callback) do
    event_name = [:pears, :recommendator, :assign_pears]

    metadata = %{team_before: Team.metadata(team)}

    callback = fn ->
      updated_team = callback.()

      metadata = %{team_after: Team.metadata(updated_team)}

      %{result: updated_team, metadata: metadata}
    end

    Tracer.trace(event_name, metadata, callback)
  end
end
