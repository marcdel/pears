defmodule PearsWeb.SlackAuthController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller

  alias Pears.Slack

  @decorate trace("slack_auth.authenticate", include: [:team_name])
  def new(conn, %{"state" => "onboard", "code" => code}) do
    team_name = conn.assigns.current_team.name

    case Slack.onboard_team(team_name, code) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Slack app successfully added!")
        |> redirect(to: ~p"/teams/slack")

      {:error, error} ->
        O11y.set_error(error)

        conn
        |> put_flash(:error, "Whoops, something went wrong! Please try again.")
        |> redirect(to: ~p"/teams/slack")

      _ ->
        O11y.set_error("Whoops, something went wrong! Please try again.")

        conn
        |> put_flash(:error, "Whoops, something went wrong! Please try again.")
        |> redirect(to: ~p"/teams/slack")
    end

    send_resp(conn, 200, "")
  end

  @decorate trace("slack_auth.missing_or_invalid_state", include: [:_params])
  def new(conn, _params) do
    send_resp(conn, 401, "")
  end
end
