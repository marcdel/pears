defmodule Pears.Repo.Migrations.UpdateTeamsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:teams) do
      add :email, :citext
      add :confirmed_at, :naive_datetime
    end

    create unique_index(:teams, [:email])

    alter table(:teams_tokens) do
      add :sent_to, :string
    end
  end
end
