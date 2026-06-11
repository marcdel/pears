defmodule PearsWeb.TeamLiveTest do
  # async: false — mutates the :send_daily_pears_summary flag, whose global
  # fun_with_flags cache entry gets rebuilt from other tests' sandboxed DB
  # connections, wiping this test's actor gate mid-run.
  use PearsWeb.ConnCase, async: false
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

  describe "with the new drag and drop flag enabled" do
    setup :register_and_log_in_team

    setup %{team: team} do
      FeatureFlags.enable(:new_drag_n_drop, for_actor: team)
      :ok
    end

    test "renders the board when the team has available pears", %{conn: conn, team: team} do
      {:ok, _} = Pears.Persistence.add_pear_to_team(team.name, "Pear One")

      {:ok, page_live, disconnected_html} = live(conn, ~p"/teams")
      assert disconnected_html =~ "Pear One"
      assert render(page_live) =~ "Pear One"
    end
  end

  describe "when logged out" do
    test "when not logged in, redirects to login", %{conn: conn} do
      {:error, {:redirect, %{to: redirected_to}}} = live(conn, "/teams")
      assert redirected_to == ~p"/teams/log_in"
    end
  end

  describe "whimsy mode celebrations" do
    setup :register_and_log_in_team

    test "board root advertises whimsy mode to the client when enabled",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, _view, html} = live(conn, ~p"/teams")

      assert html =~ ~s(data-whimsy="true")
    end

    test "board root advertises whimsy mode off by default", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/teams")

      assert html =~ ~s(data-whimsy="false")
    end

    test "toggling whimsy mode live-updates the data-whimsy attribute", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/teams")
      assert html =~ ~s(data-whimsy="false")

      view |> element(~s(button[phx-click="toggle-whimsy-mode"])) |> render_click()

      assert render(view) =~ ~s(data-whimsy="true")
    end

    test "Save pushes a confetti event when whimsy mode is on",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Save") |> render_click()

      assert_push_event(view, "whimsy:confetti", %{})
    end

    test "Save pushes no confetti event when whimsy mode is off", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Save") |> render_click()

      refute_push_event(view, "whimsy:confetti", %{})
    end

    test "Suggest pushes a drumroll event with the newly assigned pear ids when whimsy mode is on",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)
      {:ok, pear_one} = Pears.Persistence.add_pear_to_team(team.name, "Pear One")
      {:ok, pear_two} = Pears.Persistence.add_pear_to_team(team.name, "Pear Two")
      pear_ids = [pear_one.id, pear_two.id]

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      assert_push_event(view, "whimsy:drumroll", %{pears: pushed_ids})
      assert Enum.sort(pushed_ids) == Enum.sort(pear_ids)
    end

    test "Suggest pushes no drumroll event when whimsy mode is off",
         %{conn: conn, team: team} do
      {:ok, _} = Pears.Persistence.add_pear_to_team(team.name, "Pear One")

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      refute_push_event(view, "whimsy:drumroll", %{pears: _})
    end

    test "Suggest pushes no drumroll event when nothing gets assigned",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, view, _html} = live(conn, ~p"/teams")

      view |> element("button", "Suggest") |> render_click()

      refute_push_event(view, "whimsy:drumroll", %{pears: _})
    end

    test "Suggest pushes the drumroll to every connected board for the team",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)
      {:ok, pear_one} = Pears.Persistence.add_pear_to_team(team.name, "Pear One")

      {:ok, clicker, _html} = live(conn, ~p"/teams")
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_team(team)
      {:ok, watcher, _html} = live(other_conn, ~p"/teams")

      clicker |> element("button", "Suggest") |> render_click()

      assert_push_event(clicker, "whimsy:drumroll", %{pears: [pushed_id]})
      assert_push_event(watcher, "whimsy:drumroll", %{pears: [watched_id]})
      assert pushed_id == pear_one.id
      assert watched_id == pear_one.id
    end

    test "Save pushes the confetti to every connected board for the team",
         %{conn: conn, team: team} do
      FeatureFlags.enable(:whimsy_mode, for_actor: team)

      {:ok, clicker, _html} = live(conn, ~p"/teams")
      other_conn = Phoenix.ConnTest.build_conn() |> log_in_team(team)
      {:ok, watcher, _html} = live(other_conn, ~p"/teams")

      clicker |> element("button", "Save") |> render_click()

      assert_push_event(clicker, "whimsy:confetti", %{})
      assert_push_event(watcher, "whimsy:confetti", %{})
    end
  end
end
