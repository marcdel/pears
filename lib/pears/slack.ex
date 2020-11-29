defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.SlackClient

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code, slack_client \\ SlackClient) do
    token =
      slack_code
      |> slack_client.retrieve_access_tokens()
      |> Map.fetch!("access_token")

    {:ok, _token} = TeamSession.set_slack_token(team_name, token)
  end

  @decorate trace("slack.token", include: [:team_name])
  def token(team_name) do
    case TeamSession.slack_token(team_name) do
      {:ok, token} -> token
      _ -> nil
    end
  end
end
