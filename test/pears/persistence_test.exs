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
      {:ok, _} = Persistence.create_team("New Team")
      {:ok, pear} = Persistence.add_pear_to_team("New Team", "Pear One")
      {:ok, track} = Persistence.add_track_to_team("New Team", "Track One")

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

      {:ok, track} = Persistence.add_track_to_team("New Team", "Track One")
      track = Repo.preload(track, :team)
      assert track.team == team

      assert {:error, changeset} = Persistence.add_track_to_team("New Team", "Track One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "remove_track_from_team/2" do
      team_factory("New Team")
      Persistence.add_track_to_team("New Team", "Track One")

      assert {:ok, _} = Persistence.remove_track_from_team("New Team", "Track One")
    end
  end

  describe "snapshots" do
    test "can create a snapshot of the current matches" do
      team = team_factory("New Team")

      assert {:ok, snapshot} =
               Persistence.add_snapshot_to_team("New Team", [
                 {"track one", ["pear1", "pear2"]},
                 {"track two", ["pear3"]}
               ])

      snapshot = Repo.preload(snapshot, [:team, :matches])
      assert snapshot.team == team

      {:ok, %{snapshots: [snapshot]}} = Persistence.get_team_by_name("New Team")

      assert [match_one, match_two] = snapshot.matches

      matches =
        snapshot.matches
        |> Enum.map(fn match ->
          %{track_name: match.track_name, pear_names: match.pear_names}
        end)

      assert Enum.member?(matches, %{track_name: "track one", pear_names: ["pear1", "pear2"]})
      assert Enum.member?(matches, %{track_name: "track two", pear_names: ["pear3"]})
    end
  end
end
