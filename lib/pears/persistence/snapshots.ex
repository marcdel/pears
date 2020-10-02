defmodule Pears.Persistence.Snapshots do
  use OpenTelemetryDecorator

  import Ecto.Query, warn: false

  alias Pears.Persistence.SnapshotRecord
  alias Pears.Persistence.TeamRecord
  alias Pears.Repo

  @number_to_keep 30
  @excluded_team "quartz"

  @decorate trace("snapshots.prune_all", include: [:number_to_keep])
  def prune_all(opts \\ []) do
    excluded_team = Keyword.get(opts, :excluded_team, @excluded_team)

    TeamRecord
    |> where([team], team.name != ^excluded_team)
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

    Enum.map(to_delete, &Repo.delete/1)
  end
end
