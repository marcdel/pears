defmodule PearsWeb.SlackAuthControllerTest do
  # async: false — onboarding starts a TeamSession GenServer that needs
  # shared access to the SQL sandbox.
  use PearsWeb.ConnCase, async: false

  import Mox

  alias Pears.MockSlackClient
  alias Pears.SlackFixtures

  setup :verify_on_exit!
  setup :register_and_log_in_team

  describe "GET /slack/oauth" do
    test "redirects with a success flash when onboarding succeeds", %{conn: conn} do
      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.valid_token_response()
      end)

      conn =
        get(conn, ~p"/slack/oauth", %{"state" => "onboard", "code" => SlackFixtures.valid_code()})

      assert redirected_to(conn) == ~p"/teams/slack"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Slack app successfully added!"
    end

    test "redirects with an error flash when onboarding fails", %{conn: conn} do
      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.invalid_token_response()
      end)

      conn = get(conn, ~p"/slack/oauth", %{"state" => "onboard", "code" => "invalid_code"})

      assert redirected_to(conn) == ~p"/teams/slack"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Whoops, something went wrong! Please try again."
    end

    test "returns 401 when state or code is missing", %{conn: conn} do
      conn = get(conn, ~p"/slack/oauth", %{"code" => SlackFixtures.valid_code()})

      assert response(conn, 401)
    end
  end
end
