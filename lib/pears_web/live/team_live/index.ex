defmodule PearsWeb.TeamLive.Index do
  use PearsWeb, :live_view

  alias Pears.Accounts
  alias Pears.Accounts.Team

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :teams, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"name" => name}) do
    socket
    |> assign(:page_title, "Edit Team")
    |> assign(:team, Accounts.get_team_by_name(name))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Team")
    |> assign(:team, %Team{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Teams")
    |> assign(:team, nil)
  end

  @impl true
  def handle_info({PearsWeb.TeamLive.FormComponent, {:saved, team}}, socket) do
    {:noreply, stream_insert(socket, :teams, team)}
  end

  @impl true
  def handle_event("delete", %{"name" => name}, socket) do
    team = Accounts.get_team_by_name(name)

    {:noreply, stream_delete(socket, :teams, team)}
  end
end
