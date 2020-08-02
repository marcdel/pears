defmodule Pears.Core.TeamTest do
  use ExUnit.Case, async: true

  import TeamAssertions
  alias Pears.Core.Team

  setup [:team]

  test "can add and remove pears from the team", %{team: team} do
    team
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> assert_pear_available("pear1")
    |> assert_pear_available("pear2")
    |> Team.remove_pear("pear1")
    |> Team.remove_pear("pear2")
    |> refute_pear_available("pear1")
    |> refute_pear_available("pear2")
  end

  test "can add and remove a track of work", %{team: team} do
    team
    |> Team.add_track("refactor track")
    |> assert_track_exists("refactor track")
    |> Team.add_track("feature track")
    |> assert_track_exists("feature track")
    |> Team.remove_track("refactor track")
    |> refute_track_exists("refactor track")
    |> Team.remove_track("feature track")
    |> refute_track_exists("feature track")
  end

  test "can add and remove pears from tracks", %{team: team} do
    team
    |> Team.add_track("feature track")
    |> Team.add_track("refactor track")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear("pear4")
    |> Team.add_pear_to_track("pear1", "refactor track")
    |> assert_pear_in_track("pear1", "refactor track")
    |> refute_pear_available("pear1")
    |> Team.add_pear_to_track("pear2", "feature track")
    |> assert_pear_in_track("pear2", "feature track")
    |> refute_pear_available("pear2")
    |> Team.add_pear_to_track("pear3", "refactor track")
    |> assert_pear_in_track("pear3", "refactor track")
    |> refute_pear_available("pear3")
    |> Team.add_pear_to_track("pear4", "feature track")
    |> assert_pear_in_track("pear4", "feature track")
    |> refute_pear_available("pear4")
    |> Team.remove_pear_from_track("pear1", "refactor track")
    |> refute_pear_in_track("pear1", "refactor track")
    |> assert_pear_available("pear1")
    |> Team.remove_pear_from_track("pear2", "feature track")
    |> refute_pear_in_track("pear2", "feature track")
    |> assert_pear_available("pear2")
  end

  test "can move pears between tracks", %{team: team} do
    team
    |> Team.add_track("feature track")
    |> Team.add_track("refactor track")
    |> Team.add_pear("pear1")
    |> Team.add_pear_to_track("pear1", "refactor track")
    |> Team.move_pear_to_track("pear1", "refactor track", "feature track")
    |> assert_pear_in_track("pear1", "feature track")
    |> refute_pear_available("pear1")
  end

  test "assigning, unassigning, and moving pears (un)sets their track", %{team: team} do
    team =
      team
      |> Team.add_track("feature track")
      |> Team.add_track("refactor track")
      |> Team.add_pear("pear1")

    pear = Team.find_available_pear(team, "pear1")
    assert pear.track == nil

    team = Team.add_pear_to_track(team, "pear1", "refactor track")
    pear = Team.find_assigned_pear(team, "pear1")
    assert pear.track == "refactor track"

    team = Team.move_pear_to_track(team, "pear1", "refactor track", "feature track")
    pear = Team.find_assigned_pear(team, "pear1")
    assert pear.track == "feature track"
  end

  test "removing a track makes pears in that track available", %{team: team} do
    team
    |> Team.add_track("feature track")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear_to_track("pear1", "feature track")
    |> Team.add_pear_to_track("pear2", "feature track")
    |> Team.remove_track("feature track")
    |> assert_pear_available("pear1")
    |> assert_pear_available("pear2")
  end

  test "tracks are given ascending ids", %{team: team} do
    team =
      team
      |> Team.add_track("d")
      |> Team.add_track("c")
      |> Team.add_track("b")
      |> Team.add_track("a")

    tracks = Enum.map(team.tracks, fn {name, %{id: id}} -> {name, id} end)

    assert tracks == [{"a", 4}, {"b", 3}, {"c", 2}, {"d", 1}]
  end

  test "recording pears adds the current pears to the history", %{team: team} do
    team =
      team
      |> Team.add_track("feature track")
      |> Team.add_track("refactor track")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear("pear3")
      |> Team.add_pear("pear4")
      |> Team.record_pears()

    assert team.history == []

    team =
      team
      |> Team.add_pear_to_track("pear1", "refactor track")
      |> Team.add_pear_to_track("pear2", "feature track")
      |> Team.add_pear_to_track("pear3", "refactor track")
      |> Team.add_pear_to_track("pear4", "feature track")
      |> Team.record_pears()

    assert team.history == [
             [["pear2", "pear4"], ["pear1", "pear3"]]
           ]

    team =
      team
      |> Team.move_pear_to_track("pear1", "refactor track", "feature track")
      |> Team.move_pear_to_track("pear2", "feature track", "refactor track")
      |> Team.record_pears()

    assert team.history == [
             [["pear1", "pear4"], ["pear2", "pear3"]],
             [["pear2", "pear4"], ["pear1", "pear3"]]
           ]
  end

  test "can return current matches" do
    team =
      [
        {"pear1", "track one"},
        {"pear3", "track two"},
        "pear2",
        "pear4"
      ]
      |> TeamBuilders.from_matches()

    matches = Team.potential_matches(team)

    assert matches.assigned == ["pear1", "pear3"]
    assert matches.available == ["pear2", "pear4"]
  end

  test "match_in_history?/2" do
    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [["pear1", "pear2"]],
        [["pear1", "pear3"]],
        [["pear4", "pear5", "pear6"]]
      ])

    assert Team.match_in_history?(team, ["pear1", "pear2"])
    assert Team.match_in_history?(team, ["pear2", "pear1"])
    assert Team.match_in_history?(team, ["pear1", "pear3"])
    refute Team.match_in_history?(team, ["pear2", "pear3"])
    refute Team.match_in_history?(team, ["pear1", "pear4"])

    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [["pear1", "pear2", "pear3"]]
      ])

    assert Team.match_in_history?(team, ["pear1", "pear2"])
    assert Team.match_in_history?(team, ["pear2", "pear3"])
    assert Team.match_in_history?(team, ["pear1", "pear3"])
  end

  test "matched_yesterday?/2" do
    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [["pear1", "pear2"]],
        [["pear1", "pear3"]]
      ])

    assert Team.matched_yesterday?(team, ["pear1", "pear2"])
    assert Team.matched_yesterday?(team, ["pear2", "pear1"])
    refute Team.matched_yesterday?(team, ["pear1", "pear3"])
    refute Team.matched_yesterday?(team, ["pear3", "pear1"])
    refute Team.matched_yesterday?(team, ["pear2", "pear3"])
  end

  defp team(_) do
    {:ok, team: Team.new(name: "test team")}
  end
end
