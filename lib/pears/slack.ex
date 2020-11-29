defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.SlackClient

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code, slack_client \\ SlackClient) do
    with {:ok, token} <- fetch_tokens(slack_code, slack_client),
         {:ok, _} <- TeamSession.find_or_start_session(team_name),
         {:ok, _} <- TeamSession.set_slack_token(team_name, token) do
      {:ok, token}
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
end
