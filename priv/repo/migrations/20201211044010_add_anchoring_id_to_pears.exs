defmodule Pears.Repo.Migrations.AddAnchoringIdToPears do
  use Ecto.Migration

  def change do
    alter table(:pears) do
      add :anchoring_id, references(:tracks, on_delete: :nilify_all)
    end
  end
end
