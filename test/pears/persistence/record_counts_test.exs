defmodule Pears.Persistence.RecordCountsTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence.RecordCounts

  test "team_count" do
    TeamBuilders.create_teams(2)
    assert RecordCounts.team_count() == 2

    TeamBuilders.create_teams(1)
    assert RecordCounts.team_count() == 3
  end

  test "pear_count" do
    teams = TeamBuilders.create_teams(2)

    Enum.each(teams, fn team -> TeamBuilders.create_pears(team, 2) end)
    assert RecordCounts.pear_count() == 4

    Enum.each(teams, fn team -> TeamBuilders.create_pears(team, 1) end)
    assert RecordCounts.pear_count() == 6
  end

  test "track_count" do
    teams = TeamBuilders.create_teams(2)

    Enum.each(teams, fn team -> TeamBuilders.create_tracks(team, 2) end)
    assert RecordCounts.track_count() == 4

    Enum.each(teams, fn team -> TeamBuilders.create_tracks(team, 1) end)
    assert RecordCounts.track_count() == 6
  end

  test "snapshot_count" do
    teams = TeamBuilders.create_teams(2)

    Enum.each(teams, fn team -> TeamBuilders.create_snapshots(team, 2) end)
    assert RecordCounts.snapshot_count() == 4

    Enum.each(teams, fn team -> TeamBuilders.create_snapshots(team, 1) end)
    assert RecordCounts.snapshot_count() == 6
  end

  test "match_count" do
    teams = TeamBuilders.create_teams(2)

    Enum.each(teams, fn team -> TeamBuilders.create_matches(team, 2) end)
    assert RecordCounts.match_count() == 4

    Enum.each(teams, fn team -> TeamBuilders.create_matches(team, 1) end)
    assert RecordCounts.match_count() == 6
  end
end
