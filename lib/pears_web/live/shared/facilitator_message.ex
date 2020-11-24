defmodule PearsWeb.FacilitatorMessage do
  use PearsWeb, :live_component
  use OpenTelemetryDecorator

  @impl true
  def preload([assigns]) do
    {:ok, facilitator} = Pears.facilitator(assigns.team_name)
    [Map.put(assigns, :facilitator, facilitator.name)]
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
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
