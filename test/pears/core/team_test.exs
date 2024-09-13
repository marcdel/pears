defmodule Pears.Core.TeamTest do
  use ExUnit.Case, async: true

  import TeamAssertions
  alias Pears.Core.Team

  setup [:team]

  test "can add and remove pears from the team", %{team: team} do
    team
    |> Team.add_pear("pear1")
    |> assert_pear_available("pear1")
    |> Team.remove_pear("pear1")
    |> refute_pear_available("pear1")
    |> Team.add_pear("pear2")
    |> assert_pear_available("pear2")
    |> Team.add_track("refactor track")
    |> Team.add_pear_to_track("pear2", "refactor track")
    |> assert_pear_in_track("pear2", "refactor track")
    |> Team.remove_pear("pear2")
    |> refute_pear_available("pear2")
    |> refute_pear_in_track("pear2", "refactor track")
  end

  test "can update available and assigned pears", %{team: team} do
    team =
      team
      |> Team.add_track("track1")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear_to_track("pear1", "track1")
      |> Team.update_pear("pear1", slack_id: "XXXXXXXX")
      |> Team.update_pear("pear2", slack_id: "YYYYYYYY")

    [pear1] = Map.values(team.assigned_pears)
    [pear2] = Map.values(team.available_pears)

    assert pear1.slack_id == "XXXXXXXX"
    assert pear2.slack_id == "YYYYYYYY"
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
             [
               {"feature track", ["pear2", "pear4"]},
               {"refactor track", ["pear1", "pear3"]}
             ]
           ]

    team =
      team
      |> Team.move_pear_to_track("pear1", "refactor track", "feature track")
      |> Team.move_pear_to_track("pear2", "feature track", "refactor track")
      |> Team.record_pears()

    assert team.history == [
             [
               {"feature track", ["pear1", "pear4"]},
               {"refactor track", ["pear2", "pear3"]}
             ],
             [
               {"feature track", ["pear2", "pear4"]},
               {"refactor track", ["pear1", "pear3"]}
             ]
           ]
  end

  test "can return potential matches" do
    matches =
      [
        {"pear1", "incomplete track"},
        "pear2",
        {"pear3", "pear4", "full track"},
        {"pear5", "locked track"}
      ]
      |> TeamBuilders.from_matches()
      |> Team.lock_track("locked track")
      |> Team.potential_matches()

    assert matches.assigned == ["pear1"]
    assert matches.available == ["pear2"]
  end

  test "can return unlocked tracks with more than one pear" do
    tracks =
      [
        {"pear1", "incomplete track"},
        "pear2",
        {"pear3", "pear4", "full track"},
        {"pear5", "locked track"},
        {"pear6", "pear7", "full locked track"}
      ]
      |> TeamBuilders.from_matches()
      |> Team.lock_track("locked track")
      |> Team.lock_track("full locked track")
      |> Team.rotatable_tracks()

    assert Enum.count(tracks) == 1
    assert hd(tracks).name == "full track"
  end

  test "can lock/unlock a track", %{team: team} do
    team
    |> Team.add_track("track one")
    |> Team.lock_track("track one")
    |> assert_track_locked("track one")
    |> Team.unlock_track("track one")
    |> refute_track_locked("track one")
  end

  test "can toggle a pear as anchor for a track", %{team: team} do
    team
    |> Team.add_track("track1")
    |> Team.add_pear("pear1")
    |> Team.add_pear_to_track("pear1", "track1")
    |> Team.toggle_anchor("pear1", "track1")
    |> assert_anchoring_track("pear1", "track1")
    |> Team.toggle_anchor("pear1", "track1")
    |> refute_anchoring_track("pear1", "track1")
  end

  test "can automatically choose anchors for tracks", %{team: team} do
    team =
      team
      |> Team.add_track("track1")
      |> Team.add_track("track2")
      |> Team.add_track("track3")
      |> Team.add_track("track4")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear("pear3")
      |> Team.add_pear("pear4")
      |> Team.add_pear("pear5")
      |> Team.add_pear_to_track("pear1", "track1")
      |> Team.add_pear_to_track("pear2", "track2")
      |> Team.add_pear_to_track("pear3", "track2")
      |> Team.add_pear_to_track("pear4", "track3")
      |> Team.add_pear_to_track("pear5", "track3")
      |> Team.toggle_anchor("pear4", "track3")
      |> Team.choose_anchors()
      |> assert_anchoring_track("pear1", "track1")
      |> assert_anchoring_track("pear4", "track3")

    anchor = team.tracks["track2"].anchor
    assert anchor == "pear2" || anchor == "pear3"
  end

  test "can find a match in the team's history" do
    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [{"track1", ["pear1", "pear2"]}],
        [{"track1", ["pear1", "pear3"]}],
        [{"track1", ["pear4", "pear5", "pear6"]}]
      ])

    assert Team.match_in_history?(team, ["pear1", "pear2"])
    assert Team.match_in_history?(team, ["pear2", "pear1"])
    assert Team.match_in_history?(team, ["pear1", "pear3"])
    refute Team.match_in_history?(team, ["pear2", "pear3"])
    refute Team.match_in_history?(team, ["pear1", "pear4"])

    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [{"track1", ["pear1", "pear2", "pear3"]}]
      ])

    assert Team.match_in_history?(team, ["pear1", "pear2"])
    assert Team.match_in_history?(team, ["pear2", "pear3"])
    assert Team.match_in_history?(team, ["pear1", "pear3"])

    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [{"track1", ["pear1", "pear2"]}],
        [{"track1", ["pear1", "pear2", "pear3", "pear4"]}]
      ])

    assert Team.match_in_history?(team, ["pear1", "pear2"])
    assert Team.match_in_history?(team, ["pear2", "pear1"])

    # matches with more than 3 people aren't counted towards future pairing recommendations
    refute Team.match_in_history?(team, ["pear1", "pear3"])
    refute Team.match_in_history?(team, ["pear1", "pear4"])
    refute Team.match_in_history?(team, ["pear2", "pear3"])
    refute Team.match_in_history?(team, ["pear2", "pear4"])
    refute Team.match_in_history?(team, ["pear3", "pear4"])
  end

  test "can check whether two pears were matched yesterday" do
    team =
      TeamBuilders.team()
      |> Map.put(:history, [
        [{"track1", ["pear1", "pear2"]}],
        [{"track2", ["pear1", "pear3"]}]
      ])

    assert Team.matched_yesterday?(team, ["pear1", "pear2"])
    assert Team.matched_yesterday?(team, ["pear2", "pear1"])
    refute Team.matched_yesterday?(team, ["pear1", "pear3"])
    refute Team.matched_yesterday?(team, ["pear3", "pear1"])
    refute Team.matched_yesterday?(team, ["pear2", "pear3"])

    team = Map.put(team, :history, [])
    refute Team.matched_yesterday?(team, ["pear2", "pear3"])
  end

  test "can reset matches" do
    [
      {"pear2", "pear3", "track one"},
      {"pear1", "track two"}
    ]
    |> TeamBuilders.from_matches()
    |> Team.toggle_anchor("pear2", "track one")
    |> Team.reset_matches()
    |> refute_pear_in_track("pear1", "track two")
    |> assert_pear_in_track("pear2", "track one")
    |> refute_pear_in_track("pear3", "track one")
  end

  test "pears in locked tracks don't get removed on reset" do
    [
      {"pear2", "pear3", "track one"},
      {"pear1", "track two"}
    ]
    |> TeamBuilders.from_matches()
    |> Team.lock_track("track one")
    |> Team.reset_matches()
    |> refute_pear_in_track("pear1", "track two")
    |> assert_pear_in_track("pear2", "track one")
    |> assert_pear_in_track("pear3", "track one")
  end

  test "can rename a track", %{team: team} do
    team
    |> Team.add_track("track one")
    |> Team.add_pear("pear1")
    |> Team.add_pear_to_track("pear1", "track one")
    |> assert_track_exists("track one")
    |> Team.rename_track("track one", "track two")
    |> assert_track_exists("track two")
    |> assert_pear_in_track("pear1", "track two")
  end

  test "can count the available slots (slots with 0 or 1 pear in them", %{team: team} do
    slot_count =
      team
      |> Team.add_track("track zero")
      |> Team.add_track("track one")
      |> Team.add_track("track two")
      |> Team.add_track("track three")
      |> Team.lock_track("track three")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear("pear3")
      |> Team.add_pear_to_track("pear1", "track one")
      |> Team.add_pear_to_track("pear2", "track two")
      |> Team.add_pear_to_track("pear3", "track two")
      |> Team.available_slot_count()

    assert slot_count == 3
  end

  test "the order of pears within a track is stable as they're added and removed", %{team: team} do
    team
    |> Team.add_track("track1")
    |> Team.add_track("track2")
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> Team.add_pear("pear3")
    |> Team.add_pear("pear4")
    |> Team.add_pear_to_track("pear2", "track1")
    |> Team.add_pear_to_track("pear1", "track1")
    |> Team.add_pear_to_track("pear4", "track1")
    |> Team.add_pear_to_track("pear3", "track1")
    |> assert_pear_order("track1", ["pear2", "pear1", "pear4", "pear3"])
    |> Team.move_pear_to_track("pear4", "track1", "track2")
    |> Team.move_pear_to_track("pear1", "track1", "track2")
    |> assert_pear_order("track1", ["pear2", "pear3"])
    |> assert_pear_order("track2", ["pear4", "pear1"])
    |> Team.remove_pear_from_track("pear4", "track2")
    |> Team.remove_pear_from_track("pear3", "track1")
    |> assert_pear_order("available", ["pear4", "pear3"])
    |> Team.remove_pear_from_track("pear2", "track1")
    |> Team.remove_pear_from_track("pear1", "track2")
    |> assert_pear_order("available", ["pear4", "pear3", "pear2", "pear1"])
  end

  test "can check if there are active pears (available or assigned)", %{team: team} do
    team
    |> refute_has_active_pears()
    |> Team.add_pear("pear1")
    |> Team.add_pear("pear2")
    |> assert_has_active_pears()
    |> Team.add_track("track1")
    |> Team.add_pear_to_track("pear1", "track1")
    |> assert_has_active_pears()
  end

  test "can randomly select a facilitator", %{team: team} do
    assert Team.facilitator(team) == nil

    facilitator =
      team
      |> Team.add_track("track1")
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear("pear3")
      |> Team.add_pear("pear4")
      |> Team.add_pear_to_track("pear2", "track1")
      |> Team.add_pear_to_track("pear1", "track1")
      |> Team.facilitator()

    assert Enum.member?(["pear1", "pear2", "pear3", "pear4"], facilitator.name)
  end

  test "can set the team's slack channel", %{team: team} do
    assert team.slack_channel == nil
    team = Team.set_slack_channel(team, %{id: "UXXXXXXX", name: "random"})
    assert team.slack_channel == %{id: "UXXXXXXX", name: "random"}
  end

  test "can set the team's slack token", %{team: team} do
    assert team.slack_token == nil
    team = Team.set_slack_token(team, "asdasd123123")
    assert team.slack_token == "asdasd123123"
  end

  test "can calculate the timezone difference between two pears" do
    pear1 = Pears.Core.Pear.new(timezone_offset: -28800)
    pear2 = Pears.Core.Pear.new(timezone_offset: -25200)
    pear3 = Pears.Core.Pear.new(timezone_offset: -18000)

    assert Team.timezone_difference(pear1, pear2) == 1
    assert Team.timezone_difference(pear2, pear3) == 2
    assert Team.timezone_difference(pear1, pear3) == 3

    pear4 = Pears.Core.Pear.new(timezone_offset: nil)
    # If either pear has a nil timezone offset, assume same timezone
    assert Team.timezone_difference(pear1, pear4) == 0
  end

  test "can list assigned pears with different timezones" do
    team =
      TeamBuilders.team()
      |> Team.add_pear("pear1")
      |> Team.add_pear("pear2")
      |> Team.add_pear("pear3")
      |> Team.add_pear("pear4")
      |> Team.add_pear("pear5")
      |> Team.add_pear("pear6")
      # 2 EST, 1 PST
      |> Team.update_pear("pear1", timezone_offset: -18000)
      |> Team.update_pear("pear2", timezone_offset: -18000)
      |> Team.update_pear("pear3", timezone_offset: -25200)
      # Solo EST
      |> Team.update_pear("pear4", timezone_offset: -18000)
      # 2 PST
      |> Team.update_pear("pear5", timezone_offset: -25200)
      |> Team.update_pear("pear6", timezone_offset: -25200)
      |> Team.add_track("track1")
      |> Team.add_track("track2")
      |> Team.add_track("track3")
      |> Team.add_pear_to_track("pear1", "track1")
      |> Team.add_pear_to_track("pear2", "track1")
      |> Team.add_pear_to_track("pear3", "track1")
      |> Team.add_pear_to_track("pear4", "track2")
      |> Team.add_pear_to_track("pear5", "track3")
      |> Team.add_pear_to_track("pear6", "track3")

    assert [track1_pears] = Team.misaligned_tz_matches(team)
    assert Enum.map(track1_pears, &Map.get(&1, :name)) == ["pear1", "pear2", "pear3"]
  end

  test "can return the earliest pear by timezone" do
    pears = [
      Pears.Core.Pear.new(timezone_offset: -18000),
      Pears.Core.Pear.new(timezone_offset: -25200),
      Pears.Core.Pear.new(timezone_offset: -28800)
    ]

    assert Team.earliest_pear_in_match(pears).timezone_offset == -28800
  end

  defp team(_) do
    {:ok, team: Team.new(name: "test team")}
  end
end
