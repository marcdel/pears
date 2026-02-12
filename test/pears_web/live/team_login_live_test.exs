defmodule PearsWeb.TeamLoginLiveTest do
  use PearsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/teams/log_in")

      assert html =~ "Log in"
      assert html =~ "create your team"
      # assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_team(team_fixture())
        |> live(~p"/teams/log_in")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end
  end

  describe "team login" do
    test "redirects if team login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      team = team_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/teams/log_in")

      form =
        form(lv, "#login_form", team: %{name: team.name, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/teams/log_in")

      form =
        form(lv, "#login_form", team: %{name: "Some Team", password: "123456", remember_me: true})

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid name or password"

      assert redirected_to(conn) == "/teams/log_in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/log_in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "create your team")
        |> render_click()
        |> follow_redirect(conn, ~p"/teams/register")

      assert login_html =~ "Register"
    end

    @tag :skip
    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/teams/log_in")

      {:ok, conn} =
        lv
        |> element("main a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/teams/reset_password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end
end
