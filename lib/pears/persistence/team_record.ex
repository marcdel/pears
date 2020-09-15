defmodule Pears.Persistence.TeamRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pears.Persistence.PearRecord
  alias Pears.Persistence.SnapshotRecord
  alias Pears.Persistence.TrackRecord

  schema "teams" do
    field :name, :string
    has_many :pears, PearRecord, foreign_key: :team_id
    has_many :tracks, TrackRecord, foreign_key: :team_id
    has_many :snapshots, SnapshotRecord, foreign_key: :team_id

    timestamps()
  end

  @doc false
  def changeset(team_record, attrs) do
    team_record
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
