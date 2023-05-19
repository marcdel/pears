defmodule PearsWeb.PairingBoardLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  @decorate trace("team_live.mount", include: [:team_name])
  def mount(_params, _session, socket) do
    %{name: team_name} = socket.assigns.current_team
    {:ok, assign(socket, :current_name, team_name)}
  end
end
