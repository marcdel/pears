defmodule PearsWeb.TeamLive do
  use PearsWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign_team_or_redirect(params)
     |> apply_action(socket.assigns.live_action)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  @impl true
  def handle_event("recommend-pears", _params, socket) do
    {:ok, team} = Pears.recommend_pears(socket.assigns.team.name)
    {:noreply, assign(socket, :team, team)}
  end

  defp assign_team_or_redirect(socket, %{"id" => id}) do
    case Pears.lookup_team_by(id: id) do
      {:ok, team} ->
        assign(socket, :team, team)

      {:error, :not_found} ->
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, "Sorry, that team was not found")
    end
  end

  defp apply_action(socket, :show), do: socket
  defp apply_action(socket, :add_pear), do: socket
  defp apply_action(socket, :add_track), do: socket
end
