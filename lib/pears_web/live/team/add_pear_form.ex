defmodule PearsWeb.TeamLive.AddPearForm do
  use PearsWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign(pear_name: "")
    }
  end

  @impl true
  def handle_event("add_pear", %{"pear-name" => pear_name} = params, socket) do
    Pears.add_pear(socket.assigns.team_name, pear_name)
    {:noreply, push_redirect(socket, to: socket.assigns.return_to)}
  end
end
