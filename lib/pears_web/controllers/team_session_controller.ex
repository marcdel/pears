defmodule PearsWeb.TeamSessionController do
  use PearsWeb, :controller

  alias Pears.Accounts
  alias PearsWeb.TeamAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:team_return_to, ~p"/teams/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"team" => team_params}, info) do
    %{"name" => name, "password" => password} = team_params

    if team = Accounts.get_team_by_name_and_password(name, password) do
      conn
      |> put_flash(:info, info)
      |> TeamAuth.log_in_team(team, team_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the name is registered.
      conn
      |> put_flash(:error, "Invalid name or password")
      |> put_flash(:name, String.slice(name, 0, 160))
      |> redirect(to: ~p"/teams/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> TeamAuth.log_out_team()
  end
end
