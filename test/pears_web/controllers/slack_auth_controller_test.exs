defmodule PearsWeb.SlackAuthControllerTest do
  # async: false — onboarding starts a TeamSession GenServer that needs
  # shared access to the SQL sandbox.
  use PearsWeb.ConnCase, async: false

  import Mox

  alias Pears.MockSlackClient
  alias Pears.SlackFixtures

  setup :verify_on_exit!
  setup :register_and_log_in_team

  setup %{conn: conn} do
    state = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
    %{conn: put_session(conn, :slack_oauth_state, state), state: state}
  end

  describe "GET /slack/oauth" do
    test "redirects with a success flash when onboarding succeeds", %{conn: conn, state: state} do
      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.valid_token_response()
      end)

      conn =
        get(conn, ~p"/slack/oauth", %{"state" => state, "code" => SlackFixtures.valid_code()})

      assert redirected_to(conn) == ~p"/teams/slack"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Slack app successfully added!"
    end

    test "redirects with an error flash when onboarding fails", %{conn: conn, state: state} do
      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.invalid_token_response()
      end)

      conn = get(conn, ~p"/slack/oauth", %{"state" => state, "code" => "invalid_code"})

      assert redirected_to(conn) == ~p"/teams/slack"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Whoops, something went wrong! Please try again."
    end

    @tag capture_log: true
    test "rejects a state that does not match the session without contacting Slack", %{
      conn: conn
    } do
      conn =
        get(conn, ~p"/slack/oauth", %{"state" => "onboard", "code" => SlackFixtures.valid_code()})

      assert redirected_to(conn) == ~p"/teams/slack"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Whoops, something went wrong! Please try again."
    end

    @tag capture_log: true
    test "rejects a state token that is no longer in the session", %{conn: conn, state: state} do
      conn =
        conn
        |> delete_session(:slack_oauth_state)
        |> get(~p"/slack/oauth", %{"state" => state, "code" => SlackFixtures.valid_code()})

      assert redirected_to(conn) == ~p"/teams/slack"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Whoops, something went wrong! Please try again."
    end

    test "returns 401 when state or code is missing", %{conn: conn} do
      conn = get(conn, ~p"/slack/oauth", %{"code" => SlackFixtures.valid_code()})

      assert response(conn, 401)
    end
  end

  describe "slack oauth state session token" do
    test "browser requests store a state token in the session", %{conn: conn} do
      conn =
        conn
        |> delete_session(:slack_oauth_state)
        |> get(~p"/slack/oauth")

      assert is_binary(get_session(conn, :slack_oauth_state))
    end

    test "browser requests keep an existing state token", %{conn: conn, state: state} do
      conn = get(conn, ~p"/slack/oauth")

      assert get_session(conn, :slack_oauth_state) == state
    end
  end
end
