defmodule Pears.Core.TeamTest do
  use ExUnit.Case, async: true

  alias Pears.Core.{Pear, Team, Track}

  setup [:team]

  test "can add and remove pears from the team", %{team: team} do
    pear1 = Pear.new(name: "pear1")
    pear2 = Pear.new(name: "pear2")

    team
    |> Team.add_pear(pear1)
    |> Team.add_pear(pear2)
    |> assert_pear_on_team("pear1")
    |> assert_pear_on_team("pear2")
    |> Team.remove_pear(pear1)
    |> Team.remove_pear(pear2)
    |> refute_pear_on_team("pear1")
    |> refute_pear_on_team("pear2")
  end

  test "can add a track of work", %{team: team} do
    track1 = Track.new(name: "refactor track")
    team = Team.add_track(team, track1)
    assert team.tracks == [track1]

    track2 = Track.new(name: "feature track")
    team = Team.add_track(team, track2)
    assert team.tracks == [track2, track1]
  end

  test "can remove a track of work", %{team: team} do
    track1 = Track.new(name: "refactor track")
    team = Team.add_track(team, track1)
    assert team.tracks == [track1]

    team = Team.remove_track(team, track1)
    assert team.tracks == []
  end

  test "can add and remove pears from tracks", %{team: team} do
    team
    |> Team.add_track(Track.new(name: "feature track"))
    |> Team.add_track(Track.new(name: "refactor track"))
    |> Team.add_pear(Pear.new(name: "pear1"))
    |> Team.add_pear(Pear.new(name: "pear2"))
    |> Team.add_pear(Pear.new(name: "pear3"))
    |> Team.add_pear(Pear.new(name: "pear4"))
    |> Team.add_to_track("pear1", "refactor track")
    |> assert_pear_in_track("pear1", "refactor track")
    |> Team.add_to_track("pear2", "feature track")
    |> assert_pear_in_track("pear2", "feature track")
    |> Team.add_to_track("pear3", "refactor track")
    |> assert_pear_in_track("pear3", "refactor track")
    |> Team.add_to_track("pear4", "feature track")
    |> assert_pear_in_track("pear4", "feature track")
    |> Team.remove_from_track("pear1", "refactor track")
    |> refute_pear_in_track("pear1", "refactor track")
    |> Team.remove_from_track("pear2", "feature track")
    |> refute_pear_in_track("pear2", "feature track")
  end

  defp assert_pear_in_track(team, pear_name, track_name) do
    assert pear_in_track?(team, pear_name, track_name)
    team
  end

  defp refute_pear_in_track(team, pear_name, track_name) do
    refute pear_in_track?(team, pear_name, track_name)
    team
  end

  defp assert_pear_on_team(team, pear_name) do
    assert pear_on_team?(team, pear_name)
    team
  end

  defp refute_pear_on_team(team, pear_name) do
    refute pear_on_team?(team, pear_name)
    team
  end

  defp pear_on_team?(team, pear_name) do
    Team.find_pear(team, pear_name) != nil
  end

  defp pear_in_track?(team, pear_name, track_name) do
    track = Team.find_track(team, track_name)
    pear = Team.find_pear(team, pear_name)

    Enum.member?(track.pears, pear)
  end

  defp team(_) do
    {:ok, team: Team.new(name: "test team")}
  end
end
