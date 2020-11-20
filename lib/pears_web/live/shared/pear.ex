defmodule PearsWeb.Pear do
  use OpenTelemetryDecorator
  use PearsWeb, :live_component

  @impl true
  @decorate trace("team_live.toggle_anchor", include: [:team_name, :pear_name, :current_location])
  def handle_event("toggle-anchor", params, socket) do
    team_name = team_name(socket)
    pear_name = Map.get(params, "pear-name")
    current_location = Map.get(params, "current-location")

    Pears.toggle_anchor(team_name, pear_name, current_location)

    {:noreply, socket}
  end

  defp team_name(socket), do: socket.assigns.team_name
end
