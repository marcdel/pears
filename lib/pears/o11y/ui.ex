defmodule Pears.O11y.UI do
  alias Pears.O11y

  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  def recommend_pears(team, socket, callback) do
    O11y.trace(%{
      event_name: "ui.recommend_pears",
      team: team,
      attrs: %{socket_id: socket.id},
      callback: callback
    })
  end
end
