defmodule Pears.Persistence.TrackRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pears.Persistence.PearRecord
  alias Pears.Persistence.TeamRecord

  schema "tracks" do
    field :name, :string
    field :locked, :boolean
    belongs_to :team, TeamRecord, foreign_key: :team_id
    has_many :pears, PearRecord, foreign_key: :track_id

    timestamps()
  end

  @doc false
  def changeset(track_record, attrs) do
    track_record
    |> cast(attrs, [:name, :team_id, :locked])
    |> validate_required([:name, :team_id])
    |> unique_constraint([:name, :team_id], name: :tracks_team_id_name_index)
  end
end
