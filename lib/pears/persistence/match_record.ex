defmodule Pears.Persistence.MatchRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Pears.Persistence.SnapshotRecord

  schema "matches" do
    field :pear_names, {:array, :string}
    field :track_name, :string
    belongs_to :snapshot, SnapshotRecord, foreign_key: :snapshot_id

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:track_name, :pear_names])
    |> validate_required([:track_name, :pear_names])
  end
end
