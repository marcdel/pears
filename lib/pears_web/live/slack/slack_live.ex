defmodule PearsWeb.SlackLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Slack

  @impl true
  @decorate trace("slack_live.mount")
  def mount(_params, _session, socket) do
    case Slack.list_channels("demo") do
      {:ok, channels} ->
        {:ok, assign(socket, channels: channels, no_channels: Enum.empty?(channels))}

      {:error, _} ->
        {:ok, assign(socket, channels: [], no_channels: true)}
    end
  end
end
