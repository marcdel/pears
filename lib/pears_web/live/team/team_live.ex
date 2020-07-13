defmodule PearsWeb.TeamLive do
  use PearsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, team_name: "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Pears.get_team(id) do
      {:ok, team} ->
          socket
          |> assign(:team_name, team.name)
          |> assign(:team, team)

      {:error, :not_found} ->
        put_flash(socket, :error, "Sorry, that team was not found")
    end
  end

  defp apply_action(socket, :add_pear, _params) do
    socket
  end
end
