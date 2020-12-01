defmodule PearsWeb.TeamPasswordController do
  use PearsWeb, :controller

  alias Pears.Accounts
  alias PearsWeb.TeamAuth

  plug :assign_changeset

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"current_password" => password, "team" => team_params}) do
    team = conn.assigns.current_team

    case Accounts.update_team_password(team, password, team_params) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:team_return_to, Routes.team_password_path(conn, :edit))
        |> TeamAuth.log_in_team(team)

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp assign_changeset(conn, _opts) do
    team = conn.assigns.current_team
    assign(conn, :changeset, Accounts.change_team_password(team))
  end
end
