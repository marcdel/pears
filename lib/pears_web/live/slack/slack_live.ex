defmodule PearsWeb.SlackLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  @impl true
  @decorate trace("slack_live.mount")
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
