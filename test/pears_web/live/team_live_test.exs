defmodule PearsWeb.TeamLiveTest do
  use PearsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  @create_attrs %{name: "some name", password: "some password"}
  @invalid_attrs %{name: nil, password: nil}

  defp create_team(_) do
    team = team_fixture()
    %{team: team}
  end

  describe "Index" do
    setup [:create_team]

    test "registers new team", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/teams/new")

      assert index_live
             |> form("#team-form", team: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#team-form", team: @create_attrs)
             |> render_submit()

      flash = assert_redirect(index_live, ~p"/teams/some name")
      assert flash["info"] == "Team created successfully"
    end
  end

  describe "Show" do
    setup [:create_team]

    test "displays team", %{conn: conn, team: team} do
      {:ok, _show_live, html} = live(conn, ~p"/teams/#{team.name}")

      assert html =~ "Show Team"
      assert html =~ team.name
    end
  end
end
