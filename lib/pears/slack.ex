defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.Core.Team
  alias Pears.Slack.Channel
  alias Pears.Slack.Details
  alias Pears.SlackClient

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code, slack_client \\ SlackClient) do
    with {:ok, token} <- fetch_tokens(slack_code, slack_client),
         {:ok, _} <- TeamSession.find_or_start_session(team_name),
         {:ok, _} <- TeamSession.set_slack_token(team_name, token) do
      {:ok, token}
    end
  end

  @decorate trace("slack.get_details", include: [:team_name])
  def get_details(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, token} <- TeamSession.slack_token(team_name),
         {:ok, channels} <- fetch_channels(token, slack_client) do
      {:ok, Details.new(team, token, channels)}
    end
  end

  @decorate trace("slack.save_team_channel", include: [:team_name, :channel_name])
  def save_team_channel(team_name, channel_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         updated_team <- Team.update_slack_channel(team, channel_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  @decorate trace("slack.token", include: [:team_name])
  def token(team_name) do
    case TeamSession.slack_token(team_name) do
      {:ok, token} -> token
      _ -> nil
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
