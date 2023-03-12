defmodule Pears.Repo.Migrations.CreatePears do
  use Ecto.Migration

  def change do
    create table(:pears) do
      add :name, :string
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create index(:pears, [:team_id])
    create unique_index(:pears, [:team_id, :name])
  end
end
