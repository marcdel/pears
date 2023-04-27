defmodule PearsWeb.TeamConfirmationLiveTest do
  use PearsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pears.AccountsFixtures

  alias Pears.Accounts
  alias Pears.Repo

  setup do
    %{team: team_fixture()}
  end

  describe "Confirm team" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/teams/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, team: team} do
      token =
        extract_team_token(fn url ->
          Accounts.deliver_team_confirmation_instructions(team, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/teams/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/teams/log_in")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Team confirmed successfully"

      assert Accounts.get_team!(team.id).confirmed_at
      refute get_session(conn, :team_token)
      assert Repo.all(Accounts.TeamToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/teams/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/teams/log_in")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Team confirmation link is invalid or it has expired"

      # when logged in
      {:ok, lv, _html} =
        build_conn()
        |> log_in_team(team)
        |> live(~p"/teams/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/teams/log_in")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, team: team} do
      {:ok, lv, _html} = live(conn, ~p"/teams/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/teams/log_in")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Team confirmation link is invalid or it has expired"

      refute Accounts.get_team!(team.id).confirmed_at
    end
  end
end
