defmodule Pears.Boundary.PruneSnapshots do
  @moduledoc """
  We really only care about a team's most recent pairing history,
  so we prune all but the most recent snapshots for each team.
  """

  use PeriodicTask, interval: :timer.hours(1)
  use OpenTelemetryDecorator

  alias Pears.Persistence.RecordCounts
  alias Pears.Persistence.Snapshots

  @decorate trace("prune_snapshots", include: [:_snapshot_count, :updated_snapshot_count])
  def handle_tick(_snapshot_count) do
    Snapshots.prune_all()
    updated_snapshot_count = RecordCounts.snapshot_count()

    {:noreply, updated_snapshot_count}
  end
end
