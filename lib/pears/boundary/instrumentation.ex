defmodule Pears.Boundary.Instrumentation do
  alias Pears.Persistence

  def count_teams do
    count = Persistence.count_teams()
    :telemetry.execute([:pears, :teams], %{count: count})
  end
end
