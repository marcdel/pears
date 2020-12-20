defmodule Pears.Persistence.TeamRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pears.Persistence.EncryptedBinary
  alias Pears.Persistence.PearRecord
  alias Pears.Persistence.SnapshotRecord
  alias Pears.Persistence.TrackRecord

  schema "teams" do
    field :name, :string
    field :slack_channel_id, :string
    field :slack_channel_name, :string
    field :slack_token, EncryptedBinary
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

  @doc false
  def slack_token_changeset(team_record, attrs) do
    team_record
    |> cast(attrs, [:slack_token])
    |> validate_required([:slack_token])
  end

  @doc false
  def slack_channel_changeset(team_record, attrs) do
    team_record
    |> cast(attrs, [:slack_channel_id, :slack_channel_name])
    |> validate_required([:slack_channel_id, :slack_channel_name])
  end
end
