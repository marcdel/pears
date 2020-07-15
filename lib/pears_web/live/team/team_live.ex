defmodule PearsWeb.TeamLive do
  use PearsWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Pears.get_team_session_by_id(id) do
      {:ok, team} ->
          socket
          |> assign(:team_name, team.name)
          |> assign(:team, team)

      {:error, :not_found} ->
        socket
        |> assign(:team_name, "")
        |> assign(:team, %{})
        |> put_flash(:error, "Sorry, that team was not found")
    end
  end

  @impl true
  def handle_event("recommend-pears", _params, socket) do
    {:ok, team} = Pears.recommend_pears(socket.assigns.team_name)
    {:noreply, assign(socket, :team, team)}
  end


  defp apply_action(socket, :add_pear, _params), do: socket
  defp apply_action(socket, :add_track, _params), do: socket
end
