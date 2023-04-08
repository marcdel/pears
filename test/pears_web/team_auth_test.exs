defmodule PearsWeb.TeamAuthTest do
  use PearsWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Pears.Accounts
  alias PearsWeb.TeamAuth
  import Pears.AccountsFixtures

  @remember_me_cookie "_pears_web_team_remember_me"

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
      assert redirected_to(conn) == ~p"/"
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
      assert get_session(conn, :team_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
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
        |> put_req_cookie(@remember_me_cookie, team_token)
        |> fetch_cookies()
        |> TeamAuth.log_out_team()

      refute get_session(conn, :team_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_team_by_session_token(team_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "teams_sessions:abcdef-token"
      PearsWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> TeamAuth.log_out_team()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if team is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> TeamAuth.log_out_team()
      refute get_session(conn, :team_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
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

      team_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> TeamAuth.fetch_current_team([])

      assert conn.assigns.current_team.id == team.id
      assert get_session(conn, :team_token) == team_token

      assert get_session(conn, :live_socket_id) ==
               "teams_sessions:#{Base.url_encode64(team_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, team: team} do
      _ = Accounts.generate_team_session_token(team)
      conn = TeamAuth.fetch_current_team(conn, [])
      refute get_session(conn, :team_token)
      refute conn.assigns.current_team
    end
  end

  describe "on_mount: mount_current_team" do
    test "assigns current_team based on a valid team_token ", %{conn: conn, team: team} do
      team_token = Accounts.generate_team_session_token(team)
      session = conn |> put_session(:team_token, team_token) |> get_session()

      {:cont, updated_socket} =
        TeamAuth.on_mount(:mount_current_team, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_team.id == team.id
    end

    test "assigns nil to current_team assign if there isn't a valid team_token ", %{conn: conn} do
      team_token = "invalid_token"
      session = conn |> put_session(:team_token, team_token) |> get_session()

      {:cont, updated_socket} =
        TeamAuth.on_mount(:mount_current_team, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_team == nil
    end

    test "assigns nil to current_team assign if there isn't a team_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        TeamAuth.on_mount(:mount_current_team, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_team == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_team based on a valid team_token ", %{conn: conn, team: team} do
      team_token = Accounts.generate_team_session_token(team)
      session = conn |> put_session(:team_token, team_token) |> get_session()

      {:cont, updated_socket} =
        TeamAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_team.id == team.id
    end

    test "redirects to login page if there isn't a valid team_token ", %{conn: conn} do
      team_token = "invalid_token"
      session = conn |> put_session(:team_token, team_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: PearsWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = TeamAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_team == nil
    end

    test "redirects to login page if there isn't a team_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: PearsWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = TeamAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_team == nil
    end
  end

  describe "on_mount: :redirect_if_team_is_authenticated" do
    test "redirects if there is an authenticated  team ", %{conn: conn, team: team} do
      team_token = Accounts.generate_team_session_token(team)
      session = conn |> put_session(:team_token, team_token) |> get_session()

      assert {:halt, _updated_socket} =
               TeamAuth.on_mount(
                 :redirect_if_team_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated team", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               TeamAuth.on_mount(
                 :redirect_if_team_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_team_is_authenticated/2" do
    test "redirects if team is authenticated", %{conn: conn, team: team} do
      conn = conn |> assign(:current_team, team) |> TeamAuth.redirect_if_team_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
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

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> TeamAuth.require_authenticated_team([])

      assert halted_conn.halted
      assert get_session(halted_conn, :team_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> TeamAuth.require_authenticated_team([])

      assert halted_conn.halted
      assert get_session(halted_conn, :team_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
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
