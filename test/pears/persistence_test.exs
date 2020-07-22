defmodule Pears.PersistenceTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence

  describe "teams" do
    test "create_team/1" do
      {:ok, team} = Persistence.create_team("New Team")
      assert team.name == "New Team"

      assert {:error, changeset} = Persistence.create_team("New Team")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "get_team_by_name/1" do
      {:ok, team} = Persistence.create_team("New Team")
      {:ok, pear} = Persistence.add_pear_to_team("New Team", "Pear One")
      {:ok, track} = Persistence.add_track_to_team(team, "Track One")

      {:ok, loaded_team} = Persistence.get_team_by_name("New Team")
      assert loaded_team.pears == [pear]
      assert loaded_team.tracks == [track]
    end

    test "delete_team/1" do
      {:ok, _} = Persistence.create_team("New Team")
      {:ok, _} = Persistence.get_team_by_name("New Team")
      {:ok, _} = Persistence.delete_team("New Team")
      {:error, :not_found} = Persistence.get_team_by_name("New Team")
    end
  end

  def team_factory(name) do
    {:ok, team} = Persistence.create_team(name)
    team
  end

  describe "pears" do
    test "add_pear_to_team/2" do
      team = team_factory("New Team")

      {:ok, pear} = Persistence.add_pear_to_team("New Team", "Pear One")
      pear = Repo.preload(pear, :team)
      assert pear.team == team

      assert {:error, changeset} = Persistence.add_pear_to_team("New Team", "Pear One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end
  end

  describe "tracks" do
    test "add_track_to_team/2" do
      team = team_factory("New Team")

      {:ok, track} = Persistence.add_track_to_team(team, "Track One")
      track = Repo.preload(track, :team)
      assert track.team == team

      assert {:error, changeset} = Persistence.add_track_to_team(team, "Track One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "remove_track_from_team/2" do
      team = team_factory("New Team")
      Persistence.add_track_to_team(team, "Track One")

      assert {:ok, _} = Persistence.remove_track_from_team(team, "Track One")
    end
  end
end
