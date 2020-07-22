defmodule Pears.PersistenceTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
  alias Pears.Core.Team

  describe "teams" do
    test "create_team/1" do
      {:ok, team} = Persistence.create_team(Team.new(name: "New Team"))
      assert team.name == "New Team"

      assert {:error, changeset} = Persistence.create_team(Team.new(name: "New Team"))
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "get_team_by_name/1" do
      {:ok, team} = Persistence.create_team(Team.new(name: "New Team"))
      {:ok, pear} = Persistence.add_pear_to_team(team, "Pear One")
      {:ok, track} = Persistence.add_track_to_team(team, "Track One")

      {:ok, loaded_team} = Persistence.get_team_by_name("New Team")
      assert loaded_team.pears == [pear]
      assert loaded_team.tracks == [track]
    end
  end

  def team_factory(fields) do
    {:ok, team} = Persistence.create_team(Team.new(fields))
    team
  end

  describe "pears" do
    test "add_pear_to_team/2" do
      team = team_factory(name: "New Team")

      {:ok, pear} = Persistence.add_pear_to_team(team, "Pear One")
      pear = Repo.preload(pear, :team)
      assert pear.team == team

      assert {:error, changeset} = Persistence.add_pear_to_team(team, "Pear One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end
  end

  describe "tracks" do
    test "add_track_to_team/2" do
      team = team_factory(name: "New Team")

      {:ok, track} = Persistence.add_track_to_team(team, "Track One")
      track = Repo.preload(track, :team)
      assert track.team == team

      assert {:error, changeset} = Persistence.add_track_to_team(team, "Track One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "remove_track_from_team/2" do
      team = team_factory(name: "New Team")
      Persistence.add_track_to_team(team, "Track One")

      assert {:ok, _} = Persistence.remove_track_from_team(team, "Track One")
    end
  end
end
