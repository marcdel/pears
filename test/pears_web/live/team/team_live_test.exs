defmodule PearsWeb.TeamLiveTest do
  use PearsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  setup :register_and_log_in_team

  test "when is logged in team renders team page", %{conn: conn, team: team} do
    {:ok, page_live, disconnected_html} = live(conn, "/teams/#{team.name}")
    assert disconnected_html =~ team.name
    assert render(page_live) =~ team.name
  end

  test "when team does not exist redirects to registration", %{conn: conn} do
    {:error, {:redirect, %{to: redirected_to}}} = live(conn, "/teams/unknown")
    assert redirected_to == Routes.team_registration_path(conn, :new)
  end

  test "when team is different than logged in team", %{conn: conn} do
    other_team = team_fixture()
    {:error, {:redirect, %{to: redirected_to}}} = live(conn, "/teams/#{other_team.name}")
    assert redirected_to == Routes.team_registration_path(conn, :new)
  end
end
