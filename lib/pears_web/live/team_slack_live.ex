defmodule PearsWeb.TeamSlackLive do
  use PearsWeb, :live_view
  use OpenTelemetryDecorator

  alias Pears.Accounts
  alias Pears.Slack

  @impl Phoenix.LiveView
  @decorate trace("slack_live.mount", include: [:team_name, :details])
  def mount(_params, session, socket) do
    socket = assign_team(socket, session)
    socket = assign(socket, slack_link_url: Slack.link_url())
    team_name = team_name(socket)

    case Slack.get_details(team_name) do
      {:ok, details} ->
        {:ok, assign(socket, details: details)}

      {:error, details} ->
        O11y.set_error("Error getting slack details.")
        {:ok, assign(socket, details: details)}
    end
  end

  @impl Phoenix.LiveView
  @decorate trace("slack_live.save_team_channel", include: [:team_name, :team_channel_id])
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
        O11y.set_error("Error saving slack team channel.")
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  @doc """
  The actual redirection happens via the anchor tag in html, this is here to emit a telemetry event.
  """
  @impl Phoenix.LiveView
  @decorate trace("slack_live.slack_link_clicked")
  def handle_event("slack-link-clicked", value, socket) do
    O11y.set_team(socket)
    O11y.set_attribute("href", Map.get(value, "href", nil))

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
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
        O11y.set_error("Error saving slack handles.")
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
    Enum.find(socket.assigns.details.channels, &(&1.id == team_channel_id))
  end
end
