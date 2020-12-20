defmodule Pears.Repo.Migrations.AddSlackChannelToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :slack_channel, :string
    end
  end
end
