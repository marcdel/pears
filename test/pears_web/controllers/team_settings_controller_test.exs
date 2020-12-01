defmodule PearsWeb.TeamSettingsControllerTest do
  use PearsWeb.ConnCase, async: true

  alias Pears.Accounts
  import Pears.AccountsFixtures

  setup :register_and_log_in_team

  describe "GET /settings" do
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

  describe "PUT /settings" do
    @tag :capture_log
    test "updates the team name", %{conn: conn} do
      updated_name = unique_team_name()

      conn =
        put(conn, Routes.team_settings_path(conn, :update), %{
          "current_password" => valid_team_password(),
          "team" => %{"name" => updated_name}
        })

      assert redirected_to(conn) == Routes.team_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "name updated successfully"
      assert Accounts.get_team_by_name(updated_name)
    end

    test "does not update name on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.team_settings_path(conn, :update), %{
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
