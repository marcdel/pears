defmodule PearsWeb.SlackAuthController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller

  alias Pears.Slack

  @decorate trace("slack_auth_controller.authenticate", include: [:team_name])
  def new(conn, %{"state" => "onboard", "code" => code}) do
    team_name = conn.assigns.current_team.name
    Pears.O11y.set_masked_attribute(:code, code)

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

  @decorate trace("slack_auth_controller.authenticate")
  def new(conn, params) do
    O11y.set_attribute(:params, params)
    O11y.set_error("missing or invalid state")
    send_resp(conn, 401, "")
  end
end
