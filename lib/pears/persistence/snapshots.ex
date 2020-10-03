defmodule Pears.Persistence.Snapshots do
  use OpenTelemetryDecorator
  require OpenTelemetry.Span

  import Ecto.Query, warn: false

  alias Pears.Persistence.SnapshotRecord
  alias Pears.Persistence.TeamRecord
  alias Pears.Repo

  @number_to_keep 30

  @decorate trace("snapshots.prune_all", include: [:number_to_keep])
  def prune_all(opts \\ []) do
    TeamRecord
    |> Repo.all()
    |> Repo.preload(snapshots: from(s in SnapshotRecord, order_by: [desc: s.inserted_at]))
    |> Enum.flat_map(fn team_record -> prune(team_record, opts) end)
  end

  @decorate trace("snapshots.prune", include: [[:team, :name], :number_to_keep])
  def prune(team, opts \\ []) do
    number_to_keep = Keyword.get(opts, :number_to_keep, @number_to_keep)

    {_, to_delete} =
      team.snapshots
      |> Enum.sort_by(& &1.id, :desc)
      |> Enum.split(number_to_keep)

    results =
      to_delete
      |> Enum.map(&Repo.delete/1)
      |> Enum.group_by(fn {status, _} -> status end, fn {_, snapshot} -> snapshot end)

    deleted = Map.get(results, :ok, [])
    failed = Map.get(results, :error, [])

    OpenTelemetry.Span.set_attributes(
      deleted: deleted,
      deleted_count: length(deleted),
      failed: failed,
      failed_count: length(failed)
    )

    results
  end
end
