defmodule Pears.Boundary.PruneSnapshots do
  @moduledoc """
  We really only care about a team's most recent pairing history,
  so we prune all but the most recent snapshots for each team.
  """

  use GenServer
  use OpenTelemetryDecorator

  alias Pears.Persistence.RecordCounts
  alias Pears.Persistence.Snapshots

  @interval :timer.hours(1)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    send(self(), :prune_snapshots)
    {:ok, RecordCounts.snapshot_count()}
  end

  @impl GenServer
  def handle_info(:prune_snapshots, snapshot_count) do
    schedule_next()
    prune_snapshots(snapshot_count)
  end

  def schedule_next do
    Process.send_after(self(), :prune_snapshots, @interval)
  end

  @decorate trace("prune_snapshots", include: [:_snapshot_count, :updated_snapshot_count])
  def prune_snapshots(_snapshot_count) do
    Snapshots.prune_all()
    updated_snapshot_count = RecordCounts.snapshot_count()

    {:noreply, updated_snapshot_count}
  end
end
