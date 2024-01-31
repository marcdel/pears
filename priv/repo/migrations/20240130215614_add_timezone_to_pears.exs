defmodule Pears.Repo.Migrations.AddTimezoneToPears do
  use Ecto.Migration

  def change do
    alter table(:pears) do
      add :timezone_offset, :integer
    end
  end
end
