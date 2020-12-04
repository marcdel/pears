defmodule PearsWeb.SlackLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Accounts
  alias Pears.Slack

  @impl true
  @decorate trace("slack_live.mount", include: [:team_name, :details])
  def mount(_params, session, socket) do
    socket = assign_team(socket, session)
    team_name = team_name(socket)

    case Slack.get_details(team_name) do
      {:ok, details} ->
        {:ok,
         assign(socket,
           channels: details.channels,
           team_channel: details.team_channel,
           has_token: details.has_token,
           no_channels: Enum.empty?(details.channels)
         )}

      {:error, _} ->
        {:ok,
         assign(socket,
           channels: [],
           team_channel: nil,
           has_token: false,
           no_channels: true
         )}
    end
  end

  @impl true
  @decorate trace("slack_live.save_team_channel", include: [])
  def handle_event("save-team-channel", %{"team_channel" => team_channel}, socket) do
    team_name = team_name(socket)

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

  defp assign_team(socket, session) do
    team =
      session
      |> Map.get("team_token")
      |> Accounts.get_team_by_session_token()

    assign(socket, team: team)
  end

  defp team(socket), do: socket.assigns.team
  defp team_name(socket), do: team(socket).name
end