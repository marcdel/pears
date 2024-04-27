defmodule Pears.O11y.PeriodicMeasurements do
  alias Pears.Persistence.RecordCounts

  def record_counts do
    team_count = RecordCounts.team_count()
    :telemetry.execute([:pears, :teams], %{count: team_count})

    pear_count = RecordCounts.pear_count()
    :telemetry.execute([:pears, :pears], %{count: pear_count})

    track_count = RecordCounts.track_count()
    :telemetry.execute([:pears, :tracks], %{count: track_count})

    snapshot_count = RecordCounts.snapshot_count()
    :telemetry.execute([:pears, :snapshots], %{count: snapshot_count})

    match_count = RecordCounts.match_count()
    :telemetry.execute([:pears, :matches], %{count: match_count})
  end
end
