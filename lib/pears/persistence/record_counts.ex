defmodule Pears.Persistence.RecordCounts do
  alias Ecto.Adapters.SQL
  alias Pears.Accounts.TeamToken
  alias Pears.Repo
  alias Pears.Persistence.{MatchRecord, PearRecord, SnapshotRecord, TeamRecord, TrackRecord}

  def percent_full do
    total() / 10_000 * 100
  end

  def total do
    Repo
    |> SQL.query!(
      "SELECT schemaname,relname,n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;"
    )
    |> Map.get(:rows)
    |> Enum.map(fn [_schema, _table, count] -> count end)
    |> Enum.sum()
  end

  def team_count do
    Repo.aggregate(TeamRecord, :count, :id)
  end

  def pear_count do
    Repo.aggregate(PearRecord, :count, :id)
  end

  def track_count do
    Repo.aggregate(TrackRecord, :count, :id)
  end

  def snapshot_count do
    Repo.aggregate(SnapshotRecord, :count, :id)
  end

  def match_count do
    Repo.aggregate(MatchRecord, :count, :id)
  end

  def token_count do
    Repo.aggregate(TeamToken, :count, :id)
  end

  def flag_count do
    case FunWithFlags.all_flags() do
      {:ok, flags} -> Enum.count(flags)
      _ -> 0
    end
  end
end
