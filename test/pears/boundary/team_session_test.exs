defmodule Pears.Boundary.TeamSessionTest do
  use Pears.DataCase, async: true
  import TeamAssertions

  alias Pears.Boundary.TeamSession
  alias Pears.Persistence

  setup [:name]

  describe "find_or_start_session" do
    test "can lookup team by name or id", %{name: name} do
      {:ok, _} = Pears.add_team(name)

      assert {:ok, %{name: ^name}} = TeamSession.find_or_start_session(name)
      assert {:error, :not_found} = TeamSession.find_or_start_session("bad-name")
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

      {:ok, saved_team} = TeamSession.find_or_start_session(name)

      assert saved_team.name == name
      assert Enum.empty?(saved_team.available_pears)
      assert Enum.count(saved_team.assigned_pears) == 3
      assert Enum.count(saved_team.tracks) == 2

      assert Enum.count(saved_team.history) == 1

      assert Enum.member?(hd(saved_team.history), {"track two", ["pear3"]})
      assert Enum.member?(hd(saved_team.history), {"track one", ["pear1", "pear2"]})

      saved_team
      |> assert_pear_in_track("pear1", "track one")
      |> assert_pear_in_track("pear2", "track one")
      |> assert_pear_in_track("pear3", "track two")
      |> assert_track_locked("track two")
    end
  end

  def name(_) do
    {:ok, name: Ecto.UUID.generate()}
  end
end
