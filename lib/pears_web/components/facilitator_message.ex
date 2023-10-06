defmodule PearsWeb.FacilitatorMessage do
  use PearsWeb, :live_component
  use OpenTelemetryDecorator

  @impl true
  def mount(socket) do
    {:ok, facilitator} = Pears.facilitator(socket.assigns.team_name)
    {:ok, assign(socket, :facilitator, facilitator.name)}
  end

  @impl true
  @decorate trace("team_live.shuffle_facilitator", include: [:team_name])
  def handle_event("shuffle", _params, socket) do
    team_name = team_name(socket)
    {:ok, facilitator} = Pears.new_facilitator(team_name)
    {:noreply, assign(socket, :facilitator, facilitator.name)}
  end

  defp team_name(socket), do: socket.assigns.team_name
end
