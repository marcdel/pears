defmodule PearsWeb.TeamSessionController do
  use PearsWeb, :controller

  alias Pears.Accounts
  alias PearsWeb.TeamAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"team" => team_params}) do
    %{"name" => name, "password" => password} = team_params

    if team = Accounts.get_team_by_name_and_password(name, password) do
      TeamAuth.log_in_team(conn, team, team_params)
    else
      render(conn, "new.html", error_message: "team name or password were invalid")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> TeamAuth.log_out_team()
  end
end
