defmodule PearsWeb.SlackAuthController do
  use OpenTelemetryDecorator
  use PearsWeb, :controller

  alias Pears.Slack

  @decorate trace("SlackAuthController.authenticate", include: [:team_name])
  def new(conn, %{"state" => "onboard", "code" => code}) do
    team_name = conn.assigns.current_team.name

    case Slack.onboard_team(team_name, code) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Slack app successfully added!")
        |> redirect(to: Routes.team_settings_path(conn, :edit))

      _ ->
        conn
        |> put_flash(:error, "Whoops, something went wrong! Please try again.")
        |> redirect(to: Routes.team_settings_path(conn, :edit))
    end

    send_resp(conn, 200, "")
  end

  @decorate trace("SlackAuthController.missing_or_invalid_state", include: [:_params])
  def new(conn, _params) do
    send_resp(conn, 401, "")
  end
end
