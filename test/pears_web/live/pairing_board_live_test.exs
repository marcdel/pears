defmodule PearsWeb.TeamLiveTest do
  use PearsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "when logged in" do
    setup :register_and_log_in_team

    test "when is logged in team renders team page", %{conn: conn, team: team} do
      {:ok, page_live, disconnected_html} = live(conn, ~p"/teams")
      assert disconnected_html =~ team.name
      assert render(page_live) =~ team.name
    end
  end

  describe "when logged out" do
    test "when not logged in, redirects to login", %{conn: conn} do
      {:error, {:redirect, %{to: redirected_to}}} = live(conn, "/teams")
      assert redirected_to == ~p"/teams/log_in"
    end
  end
end
