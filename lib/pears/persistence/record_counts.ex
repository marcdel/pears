defmodule Pears.Persistence.RecordCounts do
  use OpenTelemetryDecorator

  alias Ecto.Adapters.SQL
  alias Pears.Accounts.TeamToken
  alias Pears.Repo
  alias Pears.Persistence.{MatchRecord, PearRecord, SnapshotRecord, TeamRecord, TrackRecord}

  @decorate trace("record_counts.percent_full", include: [:result])
  def percent_full do
    total() / 10_000 * 100
  end

  @decorate trace("record_counts.total", include: [:result])
  def total do
    Repo
    |> SQL.query!(
      "SELECT schemaname,relname,n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;"
    )
    |> Map.get(:rows)
    |> Enum.map(fn [_schema, _table, count] -> count end)
    |> Enum.sum()
  end

  @decorate trace("record_counts.team_count", include: [:result])
  def team_count do
    Repo.aggregate(TeamRecord, :count, :id)
  end

  @decorate trace("record_counts.pear_count", include: [:result])
  def pear_count do
    Repo.aggregate(PearRecord, :count, :id)
  end

  @decorate trace("record_counts.track_count", include: [:result])
  def track_count do
    Repo.aggregate(TrackRecord, :count, :id)
  end

  @decorate trace("record_counts.snapshot_count", include: [:result])
  def snapshot_count do
    Repo.aggregate(SnapshotRecord, :count, :id)
  end

  @decorate trace("record_counts.match_count", include: [:result])
  def match_count do
    Repo.aggregate(MatchRecord, :count, :id)
  end

  @decorate trace("record_counts.token_count", include: [:result])
  def token_count do
    Repo.aggregate(TeamToken, :count, :id)
  end

  @decorate trace("record_counts.flag_count", include: [:result])
  def flag_count do
    case FunWithFlags.all_flags() do
      {:ok, flags} -> Enum.count(flags)
      _ -> 0
    end
  end
end
