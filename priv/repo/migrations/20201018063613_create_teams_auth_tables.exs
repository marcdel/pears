defmodule Pears.Repo.Migrations.CreateTeamsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:teams) do
      modify :name, :citext, null: false
      add :hashed_password, :string
      add :enabled, :boolean, default: false
    end

    create table(:teams_tokens) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      timestamps(updated_at: false)
    end

    create index(:teams_tokens, [:team_id])
    create unique_index(:teams_tokens, [:context, :token])
  end
end
