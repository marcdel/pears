defmodule PearsWeb.PageLive do
  use PearsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, team_name: "")}
  end

  @impl true
  def handle_event("validate_name", %{"team-name" => team_name}, socket) do
    case Pears.validate_name(team_name) do
      :ok ->
        {:noreply, clear_flash(socket)}

      {:error, :name_taken} ->
        {:noreply, put_flash(socket, :error, "Sorry, the name \"#{team_name}\" is already taken")}
    end
  end

  @impl true
  def handle_event("create_team", %{"team-name" => team_name}, socket) do
    case Pears.add_team(team_name) do
      {:ok, team} ->
        {:noreply,
         socket
         |> put_flash(:info, "Congratulations, your team has been created!")
         |> redirect(to: Routes.show_path(socket, :show, team))}

      {:error, :name_taken} ->
        {:noreply, put_flash(socket, :error, "Sorry, the name \"#{team_name}\" is already taken")}
    end
  end
end
