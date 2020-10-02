defmodule Pears.Persistence.RecordCounts do
  alias Pears.Repo
  alias Pears.Persistence.{MatchRecord, PearRecord, SnapshotRecord, TeamRecord, TrackRecord}

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
end
