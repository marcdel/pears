defmodule PearsWeb.TeamSettingsController do
  use PearsWeb, :controller

  alias Pears.Accounts

  plug :assign_changeset

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"current_password" => password, "team" => team_params}) do
    team = conn.assigns.current_team

    case Accounts.update_team_name(team, password, team_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Team name updated successfully")
        |> redirect(to: Routes.team_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp assign_changeset(conn, _opts) do
    team = conn.assigns.current_team
    assign(conn, :changeset, Accounts.change_team_password(team))
  end
end
