defmodule PearsWeb.TeamRegistrationControllerTest do
  use PearsWeb.ConnCase, async: true

  import Pears.AccountsFixtures

  describe "GET /teams/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.team_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Create your team"
      assert response =~ "log in</a>"
    end

    test "redirects if already logged in", %{conn: conn} do
      team = team_fixture()
      conn = conn |> log_in_team(team) |> get(Routes.team_registration_path(conn, :new))
      assert redirected_to(conn) == Routes.team_path(conn, :show, team.name)
    end
  end

  describe "POST /teams/register" do
    @tag :capture_log
    test "creates account and logs the team in", %{conn: conn} do
      name = unique_team_name()

      conn =
        post(conn, Routes.team_registration_path(conn, :create), %{
          "team" => %{"name" => name, "password" => valid_team_password()}
        })

      assert get_session(conn, :team_token)
      assert redirected_to(conn) == Routes.team_path(conn, :show, name)

      # Now do a logged in request and assert on the menu
      conn = get(conn, Routes.team_path(conn, :show, name))
      response = html_response(conn, 200)
      assert response =~ name
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.team_registration_path(conn, :create), %{
          "team" => %{"name" => " ", "password" => "short"}
        })

      response = html_response(conn, 200)
      assert response =~ "Create your team"
      assert response =~ "can&#39;t be blank"
      assert response =~ "should be at least 6 character"
    end
  end
end
