defmodule Pears.Persistence.RecordCountsTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
  alias Pears.Persistence.RecordCounts

  def create_teams(count) do
    Enum.map(1..count, fn _ ->
      {:ok, team} = Persistence.create_team("Team #{Ecto.UUID.generate()}")
      team
    end)
  end

  def create_pears(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, pear} = Persistence.add_pear_to_team(team.name, "Pear #{Ecto.UUID.generate()}")
      pear
    end)
  end

  def create_tracks(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, pear} = Persistence.add_track_to_team(team.name, "Track #{Ecto.UUID.generate()}")
      pear
    end)
  end

  def create_snapshots(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, snapshot} =
        Persistence.add_snapshot_to_team(team.name, [{"track one", ["pear1", "pear2"]}])

      snapshot
    end)
  end

  def create_matches(team, count) do
    Persistence.add_snapshot_to_team(
      team.name,
      Enum.map(1..count, fn _ ->
        {"Track #{Ecto.UUID.generate()}",
         ["Track #{Ecto.UUID.generate()}", "Track #{Ecto.UUID.generate()}"]}
      end)
    )
  end

  test "team_count" do
    create_teams(2)
    assert RecordCounts.team_count() == 2

    create_teams(1)
    assert RecordCounts.team_count() == 3
  end

  test "pear_count" do
    teams = create_teams(2)

    Enum.each(teams, fn team -> create_pears(team, 2) end)
    assert RecordCounts.pear_count() == 4

    Enum.each(teams, fn team -> create_pears(team, 1) end)
    assert RecordCounts.pear_count() == 6
  end

  test "track_count" do
    teams = create_teams(2)

    Enum.each(teams, fn team -> create_tracks(team, 2) end)
    assert RecordCounts.track_count() == 4

    Enum.each(teams, fn team -> create_tracks(team, 1) end)
    assert RecordCounts.track_count() == 6
  end

  test "snapshot_count" do
    teams = create_teams(2)

    Enum.each(teams, fn team -> create_snapshots(team, 2) end)
    assert RecordCounts.snapshot_count() == 4

    Enum.each(teams, fn team -> create_snapshots(team, 1) end)
    assert RecordCounts.snapshot_count() == 6
  end

  test "match_count" do
    teams = create_teams(2)

    Enum.each(teams, fn team -> create_matches(team, 2) end)
    assert RecordCounts.match_count() == 4

    Enum.each(teams, fn team -> create_matches(team, 1) end)
    assert RecordCounts.match_count() == 6
  end
end
