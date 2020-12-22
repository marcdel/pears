defmodule PearsWeb.SlackLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Accounts
  alias Pears.Slack

  @impl true
  @decorate trace("slack_live.mount", include: [:team_name, :details])
  def mount(_params, session, socket) do
    socket = assign_team(socket, session)
    socket = assign(socket, slack_link_url: Slack.link_url())
    team_name = team_name(socket)

    case Slack.get_details(team_name) do
      {:ok, details} ->
        {:ok, assign(socket, details: details)}

      {:error, details} ->
        {:ok, assign(socket, details: details)}
    end
  end

  @impl true
  @decorate trace("slack_live.save_team_channel", include: [])
  def handle_event("save-team-channel", %{"team_channel" => team_channel_id}, socket) do
    team_name = team_name(socket)
    team_channel = team_channel(socket, team_channel_id)
    details = socket.assigns.details

    case Slack.save_team_channel(details, team_name, team_channel) do
      {:ok, details} ->
        {:noreply,
         socket
         |> assign(details: details)
         |> put_flash(:info, "Team channel successfully saved!")}

      _ ->
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  @impl true
  @decorate trace("slack_live.save_slack_handles", include: [:team_name, :params])
  def handle_event("save-slack-handles", params, socket) do
    team_name = team_name(socket)
    details = socket.assigns.details

    case Slack.save_slack_names(details, team_name, params) do
      {:ok, details} ->
        {:noreply,
         socket
         |> assign(details: details)
         |> put_flash(:info, "Slack handles successfully saved!")}

      _ ->
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  defp assign_team(socket, session) do
    team =
      session
      |> Map.get("team_token")
      |> Accounts.get_team_by_session_token()

    assign(socket, team: team)
  end

  defp team(socket), do: socket.assigns.team
  defp team_name(socket), do: team(socket).name

  defp team_channel(socket, team_channel_id) do
    Enum.find(socket.assigns.channels, &(&1.id == team_channel_id))
  end
end
