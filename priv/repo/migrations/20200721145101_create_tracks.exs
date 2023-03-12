defmodule Pears.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :name, :string
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end

    create index(:tracks, [:team_id])
    create unique_index(:tracks, [:team_id, :name])
  end
end
