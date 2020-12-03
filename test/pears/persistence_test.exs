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

    test "set_slack_token/2" do
      create_team("New Team")
      {:ok, team} = Persistence.set_slack_token("New Team", "sdkfhsdf2384")
      assert team.slack_token == "sdkfhsdf2384"
    end

    test "set_slack_channel/2" do
      create_team("New Team")
      {:ok, team} = Persistence.set_slack_channel("New Team", "random")
      assert team.slack_channel == "random"
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

  def create_team(name) do
    {:ok, team} = Persistence.create_team(name)
    team
  end

  describe "pears" do
    test "add_pear_to_team/2" do
      team = create_team("New Team")

      {:ok, pear} = Persistence.add_pear_to_team("New Team", "Pear One")
      pear = Repo.preload(pear, :team)
      assert pear.team == team

      assert {:error, changeset} = Persistence.add_pear_to_team("New Team", "Pear One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "add_pear_to_track/3" do
      create_team("New Team")

      {:ok, _} = Persistence.add_pear_to_team("New Team", "Pear One")
      {:ok, _} = Persistence.add_track_to_team("New Team", "Track One")
      {:ok, _} = Persistence.add_pear_to_track("New Team", "Pear One", "Track One")

      {:ok, team} = Persistence.get_team_by_name("New Team")
      {:ok, track} = Persistence.find_track_by_name(team, "Track One")
      {:ok, pear} = Persistence.find_pear_by_name(team, "Pear One")

      assert pear.track.id == track.id

      assert track.pears
             |> Enum.map(& &1.id)
             |> Enum.member?(pear.id)
    end
  end

  describe "tracks" do
    test "add_track_to_team/2" do
      team = create_team("New Team")

      {:ok, track} = Persistence.add_track_to_team("New Team", "Track One")
      track = Repo.preload(track, :team)
      assert track.team == team
      assert track.name == "Track One"
      assert track.locked == false

      assert {:error, changeset} = Persistence.add_track_to_team("New Team", "Track One")
      assert {"has already been taken", _} = changeset.errors[:name]
    end

    test "remove_track_from_team/2" do
      create_team("New Team")
      Persistence.add_track_to_team("New Team", "Track One")

      assert {:ok, _} = Persistence.remove_track_from_team("New Team", "Track One")
    end

    test "lock_track/2" do
      create_team("New Team")
      Persistence.add_track_to_team("New Team", "Track One")

      assert {:ok, track} = Persistence.lock_track("New Team", "Track One")
      assert track.locked == true
    end

    test "unlock_track/2" do
      create_team("New Team")
      Persistence.add_track_to_team("New Team", "Track One")
      assert {:ok, _} = Persistence.lock_track("New Team", "Track One")

      assert {:ok, track} = Persistence.unlock_track("New Team", "Track One")
      assert track.locked == false
    end

    test "rename_track/3" do
      create_team("New Team")
      Persistence.add_track_to_team("New Team", "Track One")
      assert {:ok, track} = Persistence.rename_track("New Team", "Track One", "New Track")
      assert track.name == "New Track"
    end
  end

  describe "snapshots" do
    test "can create a snapshot of the current matches" do
      team = create_team("New Team")

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
