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

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create your team")
    |> assign(:team, %Team{})
  end

  @impl true
  def handle_info({PearsWeb.TeamLive.FormComponent, {:saved, team}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Team created successfully")
     |> push_navigate(to: ~p"/teams/#{team.name}")}
  end
end
