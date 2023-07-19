defmodule PearsWeb.TeamSettingsLiveTest do
  use PearsWeb.ConnCase

  alias Pears.Accounts
  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_team(team_fixture())
        |> live(~p"/teams/settings")

      assert html =~ "Change Name"
    end

    test "redirects if team is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/teams/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update name form" do
    setup %{conn: conn} do
      password = valid_team_password()
      team = team_fixture(%{password: password})
      %{conn: log_in_team(conn, team), team: team, password: password}
    end

    test "updates the team name", %{conn: conn, password: password} do
      new_name = unique_team_name()

      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> form("#name_form", %{
          "current_password" => password,
          "team" => %{"name" => new_name}
        })
        |> render_submit()

      assert result =~ "Name changed successfully."
      assert Accounts.get_team_by_name(new_name)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> element("#name_form")
        |> render_change(%{
          "action" => "update_name",
          "current_password" => "invalid",
          "team" => %{"name" => String.duplicate("name", 100)}
        })

      assert result =~ "Change Name"
      assert result =~ "should be at most 160 character(s)"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, team: team} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> form("#name_form", %{
          "current_password" => "invalid",
          "team" => %{"name" => team.name}
        })
        |> render_submit()

      assert result =~ "Change Name"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      team = team_fixture()
      email = unique_team_email()

      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_update_email_instructions(%{team | email: email}, team.email, url)
        end)

      %{conn: log_in_team(conn, team), token: token, email: email, team: team}
    end

    test "updates the team email once", %{conn: conn, team: team, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/teams/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_team_by_email(team.email)
      assert Accounts.get_team_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/teams/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, team: team} do
      {:error, redirect} = live(conn, ~p"/teams/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_team_by_email(team.email)
    end

    test "redirects if team is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/teams/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
