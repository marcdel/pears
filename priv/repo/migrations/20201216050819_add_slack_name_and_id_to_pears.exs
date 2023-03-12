defmodule Pears.Repo.Migrations.AddSlackNameAndIdToPears do
  use Ecto.Migration

  def change do
    alter table(:pears) do
      add :slack_id, :string
      add :slack_name, :string
    end
  end
end
