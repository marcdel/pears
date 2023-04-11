defmodule PearsWeb.PageControllerTest do
  use PearsWeb.ConnCase
  import Pears.AccountsFixtures

  test "GET /", %{conn: conn} do
    team = team_fixture()

    html =
      conn
      |> log_in_team(team)
      |> get(~p"/")
      |> html_response(200)

    assert html =~ team.name
  end
end
