defmodule PearsWeb.TeamAccountLiveTest do
  use PearsWeb.ConnCase

  alias Pears.Accounts
  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_team_password()
      team = team_fixture(%{password: password})
      %{conn: log_in_team(conn, team), team: team, password: password}
    end

    test "updates the team email", %{conn: conn, password: password, team: team} do
      new_email = unique_team_email()

      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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
      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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
      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_team_password()
      team = team_fixture(%{password: password}) |> Map.delete(:email)
      %{conn: log_in_team(conn, team), team: team, password: password}
    end

    test "updates the team password", %{conn: conn, team: team, password: password} do
      new_password = valid_team_password()

      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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

      assert redirected_to(new_password_conn) == ~p"/teams/account"

      assert get_session(new_password_conn, :team_token) != get_session(conn, :team_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_team_by_name_and_password(team.name, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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
      {:ok, lv, _html} = live(conn, ~p"/teams/account")

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
end
