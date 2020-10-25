defmodule PearsWeb.TeamSettingsControllerTest do
  use PearsWeb.ConnCase, async: true

  alias Pears.Accounts
  import Pears.AccountsFixtures

  setup :register_and_log_in_team

  describe "GET /teams/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.team_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if team is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.team_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.team_session_path(conn, :new)
    end
  end

  describe "PUT /teams/settings/update_password" do
    test "updates the team password and resets tokens", %{conn: conn, team: team} do
      new_password_conn =
        put(conn, Routes.team_settings_path(conn, :update_password), %{
          "current_password" => valid_team_password(),
          "team" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.team_settings_path(conn, :edit)
      assert get_session(new_password_conn, :team_token) != get_session(conn, :team_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_team_by_name_and_password(team.name, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.team_settings_path(conn, :update_password), %{
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

  describe "PUT /teams/settings/update_name" do
    @tag :capture_log
    test "updates the team name", %{conn: conn} do
      updated_name = unique_team_name()

      conn =
        put(conn, Routes.team_settings_path(conn, :update_name), %{
          "current_password" => valid_team_password(),
          "team" => %{"name" => updated_name}
        })

      assert redirected_to(conn) == Routes.team_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "name updated successfully"
      assert Accounts.get_team_by_name(updated_name)
    end

    test "does not update name on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.team_settings_path(conn, :update_name), %{
          "current_password" => "invalid",
          "team" => %{"name" => " "}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "can&#39;t be blank"
      assert response =~ "is not valid"
    end
  end
end
