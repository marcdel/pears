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

      assert html =~ "Butt Soup"
      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if team is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/teams/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/teams/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_team_password()
      team = team_fixture(%{password: password})
      %{conn: log_in_team(conn, team), team: team, password: password}
    end

    test "updates the team email", %{conn: conn, password: password, team: team} do
      new_email = unique_team_email()

      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "team" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_team_by_email(team.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "team" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, team: team} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "team" => %{"email" => team.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
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

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_team_password()
      team = team_fixture(%{password: password}) |> Map.delete(:email)
      %{conn: log_in_team(conn, team), team: team, password: password}
    end

    test "updates the team password", %{conn: conn, team: team, password: password} do
      new_password = valid_team_password()

      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "team" => %{
            "name" => team.name,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/teams/settings"

      assert get_session(new_password_conn, :team_token) != get_session(conn, :team_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_team_by_name_and_password(team.name, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "team" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "team" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
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
