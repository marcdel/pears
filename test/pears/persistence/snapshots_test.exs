defmodule Pears.Persistence.SnapshotsTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
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

      team_with_snapshots =
        Enum.map(team_records, fn team_record ->
          {team_record, TeamBuilders.create_snapshots(team_record, 4)}
        end)

      Snapshots.prune_all(number_to_keep: 2)

      Enum.each(team_with_snapshots, fn {team_record, snapshots_before} ->
        {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
        assert length(snapshots_after) == 2
        assert oldest(snapshots_after) > oldest(snapshots_before)
      end)
    end

    test "does not delete snapshots for excluded teams" do
      team_record = TeamBuilders.create_team("cool team")
      snapshots_before = TeamBuilders.create_snapshots(team_record, 3)
      {:ok, team_record} = Persistence.get_team_by_name(team_record.name)

      Snapshots.prune_all(number_to_keep: 1, excluded_team: "cool team")

      {:ok, %{snapshots: snapshots_after}} = Persistence.get_team_by_name(team_record.name)
      assert length(snapshots_after) == length(snapshots_before)
    end
  end

  defp oldest(snapshots) do
    snapshots
    |> Enum.map(& &1.id)
    |> Enum.min()
  end
end
