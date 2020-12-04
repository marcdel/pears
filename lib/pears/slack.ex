defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.Core.Team
  alias Pears.Persistence
  alias Pears.Slack.Channel
  alias Pears.Slack.Details
  alias Pears.SlackClient

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code, slack_client \\ SlackClient) do
    with {:ok, token} <- fetch_tokens(slack_code, slack_client),
         {:ok, _} <- Persistence.set_slack_token(team_name, token),
         {:ok, team} <- TeamSession.find_or_start_session(team_name),
         updated_team <- Team.set_slack_token(team, token),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  @decorate trace("slack.get_details", include: [:team_name])
  def get_details(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, channels} <- fetch_channels(team.slack_token, slack_client) do
      {:ok, Details.new(team, channels)}
    end
  end

  @decorate trace("slack.send_message_to_team", include: [:team_name, :message])
  def send_message_to_team(team_name, message, slack_client \\ SlackClient) do
    case TeamSession.find_or_start_session(team_name) do
      {:ok, team} -> do_send_message_to_team(team, message, slack_client)
      error -> error
    end
  end

  @decorate trace("slack.save_team_channel", include: [:team_name, :channel_name])
  def save_team_channel(team_name, channel_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, _} <- Persistence.set_slack_channel(team_name, channel_name),
         updated_team <- Team.set_slack_channel(team, channel_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  defp do_send_message_to_team(team, message, slack_client) do
    case slack_client.send_message(team.slack_channel, message, team.slack_token) do
      %{"ok" => true} -> :ok
      _ -> :error
    end
  end

  defp fetch_tokens(slack_code, slack_client) do
    slack_code
    |> slack_client.retrieve_access_tokens()
    |> Map.get("access_token")
    |> case do
      nil -> {:error, :invalid_code}
      token -> {:ok, token}
    end
  end

  defp fetch_channels(nil, _slack_client), do: {:error, :no_token}

  defp fetch_channels(token, slack_client) do
    token
    |> slack_client.channels()
    |> Map.get("channels")
    |> case do
      nil -> {:error, :invalid_token}
      channels -> {:ok, Enum.map(channels, &Channel.from_json/1)}
    end
  end
end
