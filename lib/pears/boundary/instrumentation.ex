defmodule Pears.Boundary.Instrumentation do
  alias Pears.Persistence

  def count_teams do
    count = Persistence.count_teams()
    :telemetry.execute([:pears, :teams], %{count: count})
  end

  def lookup_team_by_name(name, callback) do
    start_metadata = %{team_name: name}
    event_name = [:pears, :team, :lookup_by_name]

    :telemetry.span(
      event_name,
      start_metadata,
      fn ->
        result = callback.()
        {result, Map.merge(start_metadata, %{result: result})}
      end
    )
  end

  def add_pear_to_track(team_name, pear_name, track_name, callback) do
    start_metadata = %{team_name: team_name, pear_name: pear_name, track_name: track_name}
    event_name = [:pears, :team, :add_pear_to_track]

    :telemetry.span(
      event_name,
      start_metadata,
      fn ->
        updated_team = callback.()
        {updated_team, Map.merge(start_metadata, %{updated_team: updated_team})}
      end
    )
  end
end
