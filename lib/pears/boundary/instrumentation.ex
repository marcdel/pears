defmodule Pears.Boundary.Instrumentation do
  alias Pears.Persistence

  def count_teams do
    count = Persistence.count_teams()
    :telemetry.execute([:pears, :teams], %{count: count})
  end

  def team_not_found(team_name) do
    :telemetry.execute([:pears, :team, :not_found], %{count: 1}, %{team_name: team_name})
  end
end
