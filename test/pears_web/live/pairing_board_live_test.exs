defmodule PearsWeb.TeamLiveTest do
  use PearsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Mox

  alias Pears.Slack
  alias Pears.SlackFixtures

  setup :verify_on_exit!

  describe "when logged in" do
    setup :register_and_log_in_team

    test "when is logged in team renders team page", %{conn: conn, team: team} do
      {:ok, page_live, disconnected_html} = live(conn, ~p"/teams")
      assert disconnected_html =~ team.name
      assert render(page_live) =~ team.name
    end
  end

  describe "recording pears when Slack is failing" do
    setup :register_and_log_in_team

    setup %{team: team} do
      stub(Pears.MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.valid_token_response(%{access_token: "xoxb-test-token"})
      end)

      {:ok, _} = Slack.onboard_team(team.name, "valid_code")

      {:ok, _} =
        Slack.save_team_channel(Slack.Details.empty(), team.name, %{
          id: "UXXXXXXX",
          name: "random"
        })

      FeatureFlags.enable(:send_daily_pears_summary, for_actor: team)
      :ok
    end

    test "Save still records and warns the user instead of crashing the board", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/teams")
      # The async Slack post runs in the LiveView process; allow the mock there.
      allow(Pears.MockSlackClient, self(), view.pid)

      stub(Pears.MockSlackClient, :send_message, fn _channel, _message, _token ->
        raise "TLS client: ... Unsupported Certificate (key_usage_mismatch)"
      end)

      view |> element("button", "Save") |> render_click()

      html = render(view)
      assert html =~ "recorded"
      assert html =~ "Slack summary could not be posted"
      assert Process.alive?(view.pid)
    end
  end

  describe "when logged out" do
    test "when not logged in, redirects to login", %{conn: conn} do
      {:error, {:redirect, %{to: redirected_to}}} = live(conn, "/teams")
      assert redirected_to == ~p"/teams/log_in"
    end
  end
end
