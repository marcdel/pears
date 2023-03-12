defmodule Pears.Repo.Migrations.CreateSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create index(:snapshots, [:team_id])
  end
end
