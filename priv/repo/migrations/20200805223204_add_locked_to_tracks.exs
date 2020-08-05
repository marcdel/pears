defmodule Pears.Repo.Migrations.AddLockedToTracks do
  use Ecto.Migration

  def change do
    alter table(:tracks) do
      add :locked, :boolean, default: false
    end
  end
end
