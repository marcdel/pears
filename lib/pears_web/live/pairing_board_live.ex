defmodule PearsWeb.PairingBoardLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  @decorate trace("team_live.mount", include: [[:team, :name]])
  def mount(_params, _session, socket) do
    team = socket.assigns.current_team
    {:ok, assign(socket, :current_name, team.name)}
  end
end
