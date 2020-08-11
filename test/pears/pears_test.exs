defmodule PearsTest do
  use Pears.DataCase, async: true

  import TeamAssertions
  alias Pears.Persistence

  setup [:name]

  test "happy path test", %{name: name} do
    Pears.add_team(name)

    Pears.add_pear(name, "Pear One")
    Pears.add_pear(name, "Pear Two")
    Pears.add_track(name, "Track One")

    Pears.add_pear_to_track(name, "Pear One", "Track One")
    Pears.add_pear_to_track(name, "Pear Two", "Track One")

    Pears.add_pear(name, "Pear Three")
    Pears.add_pear(name, "Pear Four")
    Pears.add_track(name, "Track Two")

    Pears.add_pear_to_track(name, "Pear Three", "Track Two")
    Pears.move_pear_to_track(name, "Pear Four", nil, "Track Two")
    Pears.remove_pear_from_track(name, "Pear Four", "Track Two")
    Pears.move_pear_to_track(name, "Pear Two", "Track One", "Track Two")

    {:ok, saved_team} = Pears.lookup_team_by(name: name)

    saved_team
    |> assert_pear_available("Pear Four")
    |> assert_pear_in_track("Pear One", "Track One")
    |> assert_pear_in_track("Pear Two", "Track Two")
    |> assert_pear_in_track("Pear Three", "Track Two")
  end

  test "can recommend pears", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_pear(name, "Pear Two")
    Pears.add_pear(name, "Pear Three")
    Pears.add_pear(name, "Pear Four")
    Pears.add_track(name, "Track One")
    Pears.add_track(name, "Track Two")
    Pears.recommend_pears(name)

    {:ok, team} = Pears.lookup_team_by(name: name)

    Enum.each(team.tracks, fn {_, track} ->
      refute Enum.empty?(track.pears)
    end)
  end

  test "recommending creates new tracks when more available pears than open tracks", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_pear(name, "Pear Two")
    Pears.add_pear(name, "Pear Three")
    Pears.add_pear(name, "Pear Four")
    Pears.add_pear(name, "Pear Five")
    Pears.add_track(name, "Track One")
    Pears.recommend_pears(name)

    {:ok, team} = Pears.lookup_team_by(name: name)

    assert Enum.count(team.tracks) == 3
    assert Enum.count(team.assigned_pears) == 5
    assert Enum.empty?(team.available_pears)
    assert Map.keys(team.tracks) == ["Track One", "Untitled Track 1", "Untitled Track 2"]
  end

  test "can record pears", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_pear(name, "Pear Two")
    Pears.add_pear(name, "Pear Three")
    Pears.add_pear(name, "Pear Four")
    Pears.add_track(name, "Track One")
    Pears.add_track(name, "Track Two")
    Pears.recommend_pears(name)

    {:ok, team} = Pears.record_pears(name)

    assert [
             [
               {"Track One", ["Pear Four", "Pear One"]},
               {"Track Two", ["Pear Three", "Pear Two"]}
             ]
           ] = team.history

    {:ok, %{snapshots: [snapshot], tracks: tracks}} = Persistence.get_team_by_name(name)

    Enum.each(tracks, fn %{pears: pears} ->
      assert Enum.all?(pears, fn pear -> pear.track != nil end)
      assert Enum.any?(pears)
    end)

    assert [_, _] = snapshot.matches
  end

  test "can remove a track", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_pear(name, "Pear Two")
    Pears.add_track(name, "Track One")
    Pears.add_pear_to_track(name, "Pear One", "Track One")
    Pears.add_pear_to_track(name, "Pear Two", "Track One")

    Pears.remove_track(name, "Track One")

    {:ok, team} = Pears.lookup_team_by(name: name)

    assert Enum.empty?(team.tracks)
    assert Enum.count(team.available_pears) == 2
  end

  test "can lock/unlock tracks", %{name: name} do
    Pears.add_team(name)
    Pears.add_track(name, "Track One")

    {:ok, team} = Pears.lock_track(name, "Track One")
    assert team.tracks |> Map.values() |> List.first() |> Map.get(:locked)

    {:ok, team} = Pears.unlock_track(name, "Track One")
    refute team.tracks |> Map.values() |> List.first() |> Map.get(:locked)
  end

  test "team names must be unique", %{name: name} do
    :ok = Pears.validate_name(name)
    {:ok, _} = Pears.add_team(name)

    {:error, :name_taken} = Pears.validate_name(name)
    {:error, :name_taken} = Pears.add_team(name)
  end

  test "can lookup team by name or id", %{name: name} do
    {:ok, _} = Pears.add_team(name)

    assert {:ok, %{name: ^name}} = Pears.lookup_team_by(name: name)
    assert {:error, :not_found} = Pears.lookup_team_by(name: "bad-name")
  end

  test "fetches team from database if not in memory", %{name: name} do
    {:ok, _} = Persistence.create_team(name)
    {:ok, _} = Persistence.add_pear_to_team(name, "pear1")
    {:ok, _} = Persistence.add_pear_to_team(name, "pear2")
    {:ok, _} = Persistence.add_pear_to_team(name, "pear3")
    {:ok, _} = Persistence.add_track_to_team(name, "track one")
    {:ok, _} = Persistence.add_track_to_team(name, "track two")
    {:ok, _} = Persistence.lock_track(name, "track two")
    {:ok, _} = Persistence.add_pear_to_track(name, "pear1", "track one")
    {:ok, _} = Persistence.add_pear_to_track(name, "pear2", "track one")
    {:ok, _} = Persistence.add_pear_to_track(name, "pear3", "track two")

    snapshot = [{"track one", ["pear1", "pear2"]}, {"track two", ["pear3"]}]
    {:ok, _} = Persistence.add_snapshot_to_team(name, snapshot)

    {:ok, saved_team} = Pears.lookup_team_by(name: name)

    assert saved_team.name == name
    assert Enum.empty?(saved_team.available_pears)
    assert Enum.count(saved_team.assigned_pears) == 3
    assert Enum.count(saved_team.tracks) == 2
    assert saved_team.history == [[{"track two", ["pear3"]}, {"track one", ["pear1", "pear2"]}]]

    saved_team
    |> assert_pear_in_track("pear1", "track one")
    |> assert_pear_in_track("pear2", "track one")
    |> assert_pear_in_track("pear3", "track two")
    |> assert_track_locked("track two")
  end

  test "removing a track removes it from the database", %{name: name} do
    {:ok, _} = Pears.add_team(name)
    {:ok, _} = Pears.add_track(name, "Track One")
    {:ok, %{tracks: [_]}} = Persistence.get_team_by_name(name)

    {:ok, _} = Pears.remove_track(name, "Track One")

    {:ok, %{tracks: []}} = Persistence.get_team_by_name(name)
  end

  test "teams can be added", %{name: name} do
    {:ok, _} = Pears.add_team(name)
    {:ok, %{name: ^name}} = Persistence.get_team_by_name(name)
  end

  test "teams can be removed", %{name: name} do
    {:ok, _} = Pears.add_team(name)
    {:ok, _} = Pears.lookup_team_by(name: name)
    {:ok, _} = Pears.remove_team(name)
    {:error, _} = Pears.lookup_team_by(name: name)
  end

  test "adding a pear to the team adds it to the database", %{name: name} do
    {:ok, _} = Pears.add_team(name)

    {:ok, _} = Pears.add_pear(name, "Pear One")

    {:ok, team} = Persistence.get_team_by_name(name)
    assert Enum.count(team.pears) == 1
    assert [%{name: "Pear One"}] = team.pears
  end

  test "adding a track to the team adds it to the database", %{name: name} do
    {:ok, _} = Pears.add_team(name)

    {:ok, _} = Pears.add_track(name, "Track One")

    {:ok, team} = Persistence.get_team_by_name(name)
    assert Enum.count(team.tracks) == 1
    assert [%{name: "Track One"}] = team.tracks
  end

  test "cannot add pear to non-existent track or non-existent pear", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_track(name, "Track One")

    assert {:error, :not_found} = Pears.add_pear_to_track(name, "Pear One", "Fake Track")
    assert {:error, :not_found} = Pears.add_pear_to_track(name, "Fake Pear", "Track One")
  end

  test "can import history from parrit", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Mansi")
    Pears.add_pear(name, "Kristin")
    Pears.add_pear(name, "Del")
    Pears.add_pear(name, "Nick")
    Pears.add_pear(name, "Iris")
    Pears.add_pear(name, "Palak")
    Pears.add_pear(name, "Luke")
    Pears.add_pear(name, "Randy")
    Pears.add_pear(name, "Marc")
    Pears.add_track(name, "Operator UI")
    Pears.add_track(name, "PTC API")
    Pears.add_track(name, "Pricing V4 ")
    Pears.add_track(name, "OOO/OC")

    json =
      ~s([{"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16983, "name": "Del"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16981, "name": "Iris"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16982, "name": "Palak"}, {"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-08-03T16:53:53.098+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16981, "name": "Iris"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16983, "name": "Del"}, {"id": 16982, "name": "Palak"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-07-31T16:23:26.362+0000"}, {"pairingBoardName": "OOO/OC", "people": [{"id": 16985, "name": "Luke"}, {"id": 16980, "name": "Randy"}, {"id": 16984, "name": "Marc"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "PTC API", "people": [{"id": 16982, "name": "Palak"}, {"id": 16981, "name": "Iris"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "Pricing V4 ", "people": [{"id": 16983, "name": "Del"}, {"id": 17859, "name": "Nick"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}, {"pairingBoardName": "Operator UI", "people": [{"id": 17443, "name": "Mansi"}, {"id": 17641, "name": "Kristin"}], "pairingTime": "2020-07-30T16:25:10.668+0000"}])

    team = Pears.import_history_from_parrit_json(name, json)

    refute Enum.empty?(team.history)
    refute Enum.empty?(team.assigned_pears)
    assert Enum.empty?(team.available_pears)
  end

  test "can change the name of a track", %{name: name} do
    Pears.add_team(name)
    Pears.add_pear(name, "Pear One")
    Pears.add_track(name, "Track One")
    Pears.add_pear_to_track(name, "Pear One", "Track One")
    Pears.record_pears(name)

    {:ok, team} = Pears.rename_track(name, "Track One", "Track Deux")
    assert %{"Track Deux" => _} = team.tracks

    Pears.Boundary.TeamManager.remove_team(name)
    Pears.Boundary.TeamSession.end_session(name)
    {:ok, team} = Pears.lookup_team_by(name: name)
    assert %{"Track Deux" => _} = team.tracks
  end

  def name(_) do
    {:ok, name: Ecto.UUID.generate()}
  end
end
