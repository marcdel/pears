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
    Pears.add_pear_to_track(name, "Pear Four", "Track Two")
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
      assert Enum.count(track.pears) == 2
    end)
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
    {:ok, _} = Persistence.add_pear_to_team(name, "Pear One")
    {:ok, _} = Persistence.add_track_to_team(name, "Track One")

    {:ok, saved_team} = Pears.lookup_team_by(name: name)

    assert saved_team.name == name
    assert Enum.count(saved_team.available_pears) == 1
    assert Enum.count(saved_team.tracks) == 1
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

  def name(_) do
    {:ok, name: Ecto.UUID.generate()}
  end
end
