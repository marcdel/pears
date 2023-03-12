defmodule Pears.Repo.Migrations.AddSlackChannelIdToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :slack_channel_id, :string
    end

    rename table(:teams), :slack_channel, to: :slack_channel_name
  end
end
