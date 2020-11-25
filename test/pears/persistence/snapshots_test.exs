defmodule Pears.Persistence.SnapshotsTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
  alias Pears.Persistence.SnapshotRecord
  alias Pears.Persistence.Snapshots

  describe "prune" do
    test "deletes snapshots and associated matches for a given team" do
      team_record = TeamBuilders.create_team()
      snapshots_before = TeamBuilders.create_snapshots(team_record, 3)
      {:ok, team_record} = Persistence.get_team_by_name(team_record.name)

      Snapshots.prune(team_record, number_to_keep: 2)

      {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
      assert length(snapshots_after) == 2
      assert oldest(snapshots_after) > oldest(snapshots_before)
    end
  end

  describe "prune_all" do
    test "deletes snapshots and associated matches for all teams" do
      team_records = TeamBuilders.create_teams(3)

      teams_with_snapshots =
        Enum.map(team_records, fn team_record ->
          {team_record, TeamBuilders.create_snapshots(team_record, 4)}
        end)

      Snapshots.prune_all(number_to_keep: 2)

      Enum.each(teams_with_snapshots, fn {team_record, snapshots_before} ->
        {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
        assert length(snapshots_after) == 2
        assert oldest(snapshots_after) > oldest(snapshots_before)
      end)
    end

    test "deletes snapshots older than 30 days" do
      team_record = TeamBuilders.create_team()
      Repo.insert!(%SnapshotRecord{inserted_at: days_ago(31), team_id: team_record.id})
      Repo.insert!(%SnapshotRecord{inserted_at: days_ago(30), team_id: team_record.id})
      Repo.insert!(%SnapshotRecord{inserted_at: days_ago(29), team_id: team_record.id})

      Snapshots.prune_all()

      {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
      assert length(snapshots_after) == 2
    end

    test "deletes snapshots older than 30 days and greater than number to keep" do
      team_record = TeamBuilders.create_team()

      # This one would be deleted because it's too old and
      # because there's more than the number_to_keep and it's the oldest
      Repo.insert!(%SnapshotRecord{inserted_at: days_ago(31), team_id: team_record.id})
      Repo.insert!(%SnapshotRecord{inserted_at: days_ago(29), team_id: team_record.id})

      Snapshots.prune_all(number_to_keep: 1)

      {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
      assert length(snapshots_after) == 1
    end
  end

  defp days_ago(days) do
    seconds = -(days * 24 * 3600)

    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(seconds, :second)
    |> NaiveDateTime.truncate(:second)
  end

  defp oldest(snapshots) do
    snapshots
    |> Enum.map(& &1.id)
    |> Enum.min()
  end
end
