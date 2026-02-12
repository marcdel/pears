defmodule PearsWeb.TeamRegistrationLiveTest do
  use PearsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/teams/register")

      assert html =~ "Register"
      assert html =~ "log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_team(team_fixture())
        |> live(~p"/teams/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(team: %{"name" => String.duplicate("name", 100), "password" => "short"})

      assert result =~ "Register"
      assert result =~ "should be at most 160 character(s)"
      assert result =~ "should be at least 12 character(s)"
    end
  end

  describe "register team" do
    test "creates account and logs the team in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/register")

      name = unique_team_name()
      attrs = valid_team_attributes(name: name) |> Map.delete(:email)
      form = form(lv, "#registration_form", team: attrs)
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      # TODO: uncomment once redirect to /teams/:name is done
      # assert response =~ name
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/register")

      team = team_fixture(%{name: "popular name"})

      result =
        lv
        |> form("#registration_form",
          team: %{"name" => team.name, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/teams/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/teams/log_in")

      assert login_html =~ "Log in"
    end
  end
end
