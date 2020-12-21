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
        {:ok,
         assign(socket,
           channels: details.channels,
           pears: details.pears,
           users: details.users,
           team_channel: details.team_channel,
           has_token: details.has_token,
           no_channels: Enum.empty?(details.channels),
           all_pears_updated: details.all_pears_updated
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           channels: [],
           pears: [],
           users: [],
           team_channel: %{id: nil, name: ""},
           has_token: false,
           no_channels: true,
           all_pears_updated: false
         )}
    end
  end

  @impl true
  @decorate trace("slack_live.save_team_channel", include: [])
  def handle_event("save-team-channel", %{"team_channel" => team_channel_id}, socket) do
    team_name = team_name(socket)
    team_channel = team_channel(socket, team_channel_id)

    case Slack.save_team_channel(team_name, team_channel) do
      {:ok, team} ->
        {:noreply,
         socket
         |> assign(team: team, team_channel: team_channel)
         |> put_flash(:info, "Team channel successfully saved!")}

      _ ->
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  @impl true
  @decorate trace("slack_live.save_slack_handles", include: [:team_name, :params])
  def handle_event("save-slack-handles", params, socket) do
    team_name = team_name(socket)
    users = socket.assigns.users

    case Slack.save_slack_names(team_name, users, params) do
      {:ok, pears} ->
        {:noreply,
         socket
         |> assign(pears: pears)
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
