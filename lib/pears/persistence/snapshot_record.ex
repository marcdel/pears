defmodule Pears.Persistence.SnapshotRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pears.Persistence.{MatchRecord, TeamRecord}

  schema "snapshots" do
    belongs_to :team, TeamRecord, foreign_key: :team_id
    has_many :matches, MatchRecord, foreign_key: :snapshot_id

    timestamps()
  end

  def from_today?(snapshot, today \\ Date.utc_today()) do
    Date.compare(NaiveDateTime.to_date(snapshot.inserted_at), today) == :eq
  end

  @doc false
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:team_id])
    |> cast_assoc(:matches, with: &MatchRecord.changeset/2)
    |> validate_required([])
  end
end
