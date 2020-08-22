defmodule PearsWeb.TeamLive.TestComponent do
  use PearsWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("reset-pears", _params, socket) do
    {:ok, team} = Pears.reset_pears(socket.assigns.team_name)

    {:noreply, socket}
  end
end
