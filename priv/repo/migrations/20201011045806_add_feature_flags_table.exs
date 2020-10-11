defmodule Pears.Repo.Migrations.AddFeatureFlagsTable do
  use Ecto.Migration

  def up do
    create table(:feature_flags, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :flag_name, :string, null: false
      add :gate_type, :string, null: false
      add :target, :string, null: false
      add :enabled, :boolean, null: false
    end

    create index(
             :feature_flags,
             [:flag_name, :gate_type, :target],
             [unique: true, name: "feature_flags_flag_name_gate_target_idx"]
           )
  end

  def down do
    drop table(:feature_flags)
  end
end
