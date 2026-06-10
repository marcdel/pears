defmodule PearsWeb.TeamForgotPasswordLiveTest do
  use PearsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  describe "Forgot password page" do
    test "renders an unavailable notice instead of the email form", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/teams/reset_password")

      assert html =~ "Password reset is currently unavailable"
      refute has_element?(lv, "#reset_password_form")
      assert has_element?(lv, ~s|a[href="#{~p"/teams/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/teams/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_team(team_fixture())
        |> live(~p"/teams/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end
end
