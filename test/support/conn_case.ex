defmodule PearsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use PearsWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import PearsWeb.ConnCase

      alias PearsWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint PearsWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Pears.Repo)

    unless tags[:async] do
      Sandbox.mode(Pears.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in teams.

      setup :register_and_log_in_team

  It stores an updated connection and a registered team in the
  test context.
  """
  def register_and_log_in_team(%{conn: conn}) do
    team = Pears.AccountsFixtures.team_fixture()
    %{conn: log_in_team(conn, team), team: team}
  end

  @doc """
  Logs the given `team` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_team(conn, team) do
    token = Pears.Accounts.generate_team_session_token(team)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:team_token, token)
  end
end
