defmodule PearsWeb.TeamLive.AddTrackForm do
  use PearsWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
      |> assign(track_name: "")
    }
  end

  @impl true
  def handle_event("add_track", %{"track-name" => track_name} = params, socket) do
    Pears.add_track(socket.assigns.team_name, track_name)
    {:noreply, push_redirect(socket, to: socket.assigns.return_to)}
  end
end
