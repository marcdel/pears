defmodule PearsWeb.HomeControllerTest do
  use PearsWeb.ConnCase, async: true

  import Pears.AccountsFixtures

  describe "GET /" do
    test "redirects to team page if already logged in", %{conn: conn} do
      team = team_fixture()
      conn = conn |> log_in_team(team) |> get(Routes.home_path(conn, :show))
      assert redirected_to(conn) == Routes.team_path(conn, :show, team.name)
    end

    test "redirects to registration page if not logged in", %{conn: conn} do
      conn = get(conn, Routes.home_path(conn, :show))
      assert redirected_to(conn) == Routes.team_registration_path(conn, :new)
    end
  end
end
