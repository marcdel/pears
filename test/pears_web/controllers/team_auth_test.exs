defmodule PearsWeb.TeamAuthTest do
  use PearsWeb.ConnCase, async: true

  alias Pears.Accounts
  alias PearsWeb.TeamAuth
  import Pears.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, PearsWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{team: team_fixture(), conn: conn}
  end

  describe "log_in_team/3" do
    test "stores the team token in the session", %{conn: conn, team: team} do
      conn = TeamAuth.log_in_team(conn, team)
      assert token = get_session(conn, :team_token)
      assert get_session(conn, :live_socket_id) == "teams_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/teams/#{team.name}"
      assert Accounts.get_team_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, team: team} do
      conn = conn |> put_session(:to_be_removed, "value") |> TeamAuth.log_in_team(team)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, team: team} do
      conn = conn |> put_session(:team_return_to, "/hello") |> TeamAuth.log_in_team(team)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, team: team} do
      conn = conn |> fetch_cookies() |> TeamAuth.log_in_team(team, %{"remember_me" => "true"})
      assert get_session(conn, :team_token) == conn.cookies["team_remember_me"]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies["team_remember_me"]
      assert signed_token != get_session(conn, :team_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_team/1" do
    test "erases session and cookies", %{conn: conn, team: team} do
      team_token = Accounts.generate_team_session_token(team)

      conn =
        conn
        |> put_session(:team_token, team_token)
        |> put_req_cookie("team_remember_me", team_token)
        |> fetch_cookies()
        |> TeamAuth.log_out_team()

      refute get_session(conn, :team_token)
      refute conn.cookies["team_remember_me"]
      assert %{max_age: 0} = conn.resp_cookies["team_remember_me"]
      assert redirected_to(conn) == ~p"/teams/log_in"
      refute Accounts.get_team_by_session_token(team_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "teams_sessions:abcdef-token"
      PearsWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> TeamAuth.log_out_team()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "teams_sessions:abcdef-token"
      }
    end

    test "works even if team is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> TeamAuth.log_out_team()
      refute get_session(conn, :team_token)
      assert %{max_age: 0} = conn.resp_cookies["team_remember_me"]
      assert redirected_to(conn) == ~p"/teams/log_in"
    end
  end

  describe "fetch_current_team/2" do
    test "authenticates team from session", %{conn: conn, team: team} do
      team_token = Accounts.generate_team_session_token(team)
      conn = conn |> put_session(:team_token, team_token) |> TeamAuth.fetch_current_team([])
      assert conn.assigns.current_team.id == team.id
    end

    test "authenticates team from cookies", %{conn: conn, team: team} do
      logged_in_conn =
        conn |> fetch_cookies() |> TeamAuth.log_in_team(team, %{"remember_me" => "true"})

      team_token = logged_in_conn.cookies["team_remember_me"]
      %{value: signed_token} = logged_in_conn.resp_cookies["team_remember_me"]

      conn =
        conn
        |> put_req_cookie("team_remember_me", signed_token)
        |> TeamAuth.fetch_current_team([])

      assert get_session(conn, :team_token) == team_token
      assert conn.assigns.current_team.id == team.id
    end

    test "does not authenticate if data is missing", %{conn: conn, team: team} do
      _ = Accounts.generate_team_session_token(team)
      conn = TeamAuth.fetch_current_team(conn, [])
      refute get_session(conn, :team_token)
      refute conn.assigns.current_team
    end
  end

  describe "redirect_if_team_is_authenticated/2" do
    test "redirects if team is authenticated", %{conn: conn, team: team} do
      conn = conn |> assign(:current_team, team) |> TeamAuth.redirect_if_team_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/teams/#{team.name}"
    end

    test "does not redirect if team is not authenticated", %{conn: conn} do
      conn = TeamAuth.redirect_if_team_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_team/2" do
    test "redirects if team is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> TeamAuth.require_authenticated_team([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/teams/log_in"
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> TeamAuth.require_authenticated_team([])

      assert halted_conn.halted
      assert get_session(halted_conn, :team_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> TeamAuth.require_authenticated_team([])

      assert halted_conn.halted
      assert get_session(halted_conn, :team_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> TeamAuth.require_authenticated_team([])

      assert halted_conn.halted
      refute get_session(halted_conn, :team_return_to)
    end

    test "does not redirect if team is authenticated", %{conn: conn, team: team} do
      conn = conn |> assign(:current_team, team) |> TeamAuth.require_authenticated_team([])
      refute conn.halted
      refute conn.status
    end
  end
end
