defmodule Pears.Repo.Migrations.AddTrackIdToPears do
  use Ecto.Migration

  def change do
    alter table(:pears) do
      add :track_id, references(:tracks, on_delete: :nilify_all)
    end
  end
end
