defmodule Pears.Repo.Migrations.AddSlackTokenToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :slack_token, :binary
    end
  end
end
