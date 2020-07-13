defmodule PearsWeb.Team.ShowLive do
  use PearsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, team_name: "")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    case Pears.get_team(id) do
      {:ok, team} ->
        {:noreply,
         socket
         |> assign(:team_name, team.name)}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Sorry, that team was not found")}
    end
  end
end
