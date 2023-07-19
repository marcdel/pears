defmodule PearsWeb.TeamSessionControllerTest do
  use PearsWeb.ConnCase, async: true

  import Pears.AccountsFixtures

  setup do
    %{team: team_fixture()}
  end

  describe "POST /teams/log_in" do
    test "logs the team in", %{conn: conn, team: team} do
      conn =
        post(conn, ~p"/teams/log_in", %{
          "team" => %{"name" => team.name, "password" => valid_team_password()}
        })

      assert get_session(conn, :team_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      # TODO: uncomment once redirect to /teams/:name is done
      # assert response =~ team.name
      assert response =~ ~p"/teams/settings"
      assert response =~ ~p"/teams/log_out"
    end

    test "logs the team in with remember me", %{conn: conn, team: team} do
      conn =
        post(conn, ~p"/teams/log_in", %{
          "team" => %{
            "name" => team.name,
            "password" => valid_team_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_pears_web_team_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the team in with return to", %{conn: conn, team: team} do
      conn =
        conn
        |> init_test_session(team_return_to: "/foo/bar")
        |> post(~p"/teams/log_in", %{
          "team" => %{
            "name" => team.name,
            "password" => valid_team_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, team: team} do
      conn =
        conn
        |> post(~p"/teams/log_in", %{
          "_action" => "registered",
          "team" => %{
            "name" => team.name,
            "password" => valid_team_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, team: team} do
      conn =
        conn
        |> post(~p"/teams/log_in", %{
          "_action" => "password_updated",
          "team" => %{
            "name" => team.name,
            "password" => valid_team_password()
          }
        })

      assert redirected_to(conn) == ~p"/teams/account"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/teams/log_in", %{
          "team" => %{"name" => "Team Name", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid name or password"
      assert redirected_to(conn) == ~p"/teams/log_in"
    end
  end

  describe "DELETE /teams/log_out" do
    test "logs the team out", %{conn: conn, team: team} do
      conn = conn |> log_in_team(team) |> delete(~p"/teams/log_out")
      assert redirected_to(conn) == ~p"/teams/log_in"
      refute get_session(conn, :team_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the team is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/teams/log_out")
      assert redirected_to(conn) == ~p"/teams/log_in"
      refute get_session(conn, :team_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
