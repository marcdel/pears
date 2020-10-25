defmodule PearsWeb.TeamSessionControllerTest do
  use PearsWeb.ConnCase, async: true

  import Pears.AccountsFixtures

  setup do
    %{team: team_fixture()}
  end

  describe "GET /teams/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.team_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "create your team"
    end

    test "redirects if already logged in", %{conn: conn, team: team} do
      conn = conn |> log_in_team(team) |> get(Routes.team_session_path(conn, :new))
      assert redirected_to(conn) == Routes.team_path(conn, :show, team.name)
    end
  end

  describe "POST /teams/log_in" do
    test "logs the team in", %{conn: conn, team: team} do
      conn =
        post(conn, Routes.team_session_path(conn, :create), %{
          "team" => %{"name" => team.name, "password" => valid_team_password()}
        })

      assert get_session(conn, :team_token)
      assert redirected_to(conn) == Routes.team_path(conn, :show, team.name)

      # Now do a logged in request and assert on the menu
      conn = get(conn, Routes.team_path(conn, :show, team.name))
      response = html_response(conn, 200)
      assert response =~ team.name
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the team in with remember me", %{conn: conn, team: team} do
      conn =
        post(conn, Routes.team_session_path(conn, :create), %{
          "team" => %{
            "name" => team.name,
            "password" => valid_team_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["team_remember_me"]
      assert redirected_to(conn) == Routes.team_path(conn, :show, team.name)
    end

    test "emits error message with invalid credentials", %{conn: conn, team: team} do
      conn =
        post(conn, Routes.team_session_path(conn, :create), %{
          "team" => %{"name" => team.name, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "team name or password were invalid"
    end
  end

  describe "DELETE /teams/log_out" do
    test "logs the team out", %{conn: conn, team: team} do
      conn = conn |> log_in_team(team) |> delete(Routes.team_session_path(conn, :delete))
      assert redirected_to(conn) == Routes.team_session_path(conn, :create)
      refute get_session(conn, :team_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the team is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.team_session_path(conn, :delete))
      assert redirected_to(conn) == Routes.team_session_path(conn, :create)
      refute get_session(conn, :team_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
