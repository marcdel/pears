defmodule PearsWeb.TeamRegistrationController do
  use PearsWeb, :controller

  alias Pears.Accounts
  alias Pears.Accounts.Team
  alias PearsWeb.TeamAuth

  def new(conn, _params) do
    changeset = Accounts.change_team_registration(%Team{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"team" => team_params}) do
    case Accounts.register_team(team_params) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Team created successfully.")
        |> TeamAuth.log_in_team(team)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
