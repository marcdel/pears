defmodule PearsWeb.SlackAuthController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller

  require Logger

  alias Pears.Slack
  alias Pears.Slack.OAuthState

  @decorate trace("slack_auth_controller.authenticate", include: [:team_name])
  def new(conn, %{"state" => state, "code" => code}) do
    team_name = conn.assigns.current_team.name
    Pears.O11y.set_masked_attribute(:code, code)

    if OAuthState.valid?(get_session(conn, :slack_oauth_state), state) do
      onboard(conn, team_name, code)
    else
      O11y.set_error("oauth state mismatch")
      Logger.warning("Rejected Slack OAuth callback for team #{team_name}: state mismatch")
      error_redirect(conn)
    end
  end

  @decorate trace("slack_auth_controller.authenticate")
  def new(conn, params) do
    O11y.set_attribute(:params, params)
    O11y.set_error("missing or invalid state")
    send_resp(conn, 401, "")
  end

  defp onboard(conn, team_name, code) do
    case Slack.onboard_team(team_name, code) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Slack app successfully added!")
        |> redirect(to: ~p"/teams/slack")

      {:error, error} ->
        O11y.set_error(error)
        error_redirect(conn)

      _ ->
        O11y.set_error("Whoops, something went wrong! Please try again.")
        error_redirect(conn)
    end
  end

  defp error_redirect(conn) do
    conn
    |> put_flash(:error, "Whoops, something went wrong! Please try again.")
    |> redirect(to: ~p"/teams/slack")
  end
end
