defmodule PearsWeb.TeamPasswordControllerTest do
  use PearsWeb.ConnCase, async: true

  alias Pears.Accounts
  import Pears.AccountsFixtures

  setup :register_and_log_in_team

  describe "GET /settings/password" do
    test "renders password settings page", %{conn: conn} do
      conn = get(conn, Routes.team_password_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if team is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.team_password_path(conn, :edit))
      assert redirected_to(conn) == Routes.team_session_path(conn, :new)
    end
  end

  describe "PUT /settings/password" do
    test "updates the team password and resets tokens", %{conn: conn, team: team} do
      new_password_conn =
        put(conn, Routes.team_password_path(conn, :update), %{
          "current_password" => valid_team_password(),
          "team" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.team_password_path(conn, :edit)
      assert get_session(new_password_conn, :team_token) != get_session(conn, :team_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_team_by_name_and_password(team.name, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.team_password_path(conn, :update), %{
          "current_password" => "invalid",
          "team" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Settings"
      assert response =~ "should be at least 6 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :team_token) == get_session(conn, :team_token)
    end
  end
end
