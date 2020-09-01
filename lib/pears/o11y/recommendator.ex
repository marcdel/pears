defmodule Pears.O11y.Recommendator do
  alias Pears.O11y

  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  def assign_pears(team, parent_ctx, callback) do
    O11y.trace(%{
      event_name: "recommendator.recommend_pears",
      team: team,
      parent_ctx: parent_ctx,
      callback: callback
    })
  end
end
