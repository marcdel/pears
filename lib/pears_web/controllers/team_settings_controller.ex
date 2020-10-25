defmodule PearsWeb.TeamSettingsController do
  use PearsWeb, :controller

  alias Pears.Accounts
  alias PearsWeb.TeamAuth

  plug :assign_name_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update_name(conn, %{"current_password" => password, "team" => team_params}) do
    team = conn.assigns.current_team

    case Accounts.update_team_name(team, password, team_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Team name updated successfully")
        |> redirect(to: Routes.team_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", name_changeset: changeset)
    end
  end

  def update_password(conn, %{"current_password" => password, "team" => team_params}) do
    team = conn.assigns.current_team

    case Accounts.update_team_password(team, password, team_params) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:team_return_to, Routes.team_settings_path(conn, :edit))
        |> TeamAuth.log_in_team(team)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  defp assign_name_and_password_changesets(conn, _opts) do
    team = conn.assigns.current_team

    conn
    |> assign(:name_changeset, Accounts.change_team_name(team))
    |> assign(:password_changeset, Accounts.change_team_password(team))
  end
end
