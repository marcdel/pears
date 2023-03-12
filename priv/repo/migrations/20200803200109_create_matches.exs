defmodule Pears.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :track_name, :string
      add :pear_names, {:array, :string}
      add :snapshot_id, references(:snapshots, on_delete: :delete_all)

      timestamps()
    end

    create index(:matches, [:snapshot_id])
  end
end
