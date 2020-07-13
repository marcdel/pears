defmodule PearsTest do
  use ExUnit.Case, async: true

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

    Pears.persist_changes(name)

    {:ok, saved_team} = Pears.lookup_team_by_name(name)
    {:ok, unsaved_team} = Pears.get_unsaved_team(name)

    assert unsaved_team == saved_team

    assert saved_team == %Pears.Core.Team{
             available_pears: %{},
             name: name,
             id: name,
             tracks: %{
               "Track One" => %Pears.Core.Track{
                 name: "Track One",
                 pears: %{
                   "Pear One" => %Pears.Core.Pear{name: "Pear One"},
                   "Pear Two" => %Pears.Core.Pear{name: "Pear Two"}
                 }
               },
               "Track Two" => %Pears.Core.Track{
                 name: "Track Two",
                 pears: %{
                   "Pear Three" => %Pears.Core.Pear{name: "Pear Three"},
                   "Pear Four" => %Pears.Core.Pear{name: "Pear Four"}
                 }
               }
             }
           }
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

    {:ok, team} = Pears.get_unsaved_team(name)

    Enum.each(team.tracks, fn {_, track} ->
      assert Enum.count(track.pears) == 2
    end)
  end

  test "team names must be unique", %{name: name} do
    :ok = Pears.validate_name(name)
    {:ok, _} = Pears.add_team(name)

    {:error, :name_taken} = Pears.validate_name(name)
    {:error, :name_taken} = Pears.add_team(name)
  end

  test "converts name to url-safe id" do
    assert {:ok, %{id: "with-caps-spaces"}} = Pears.add_team("With Caps Spaces")
  end

  test "can lookup team by id", %{name: name} do
    {:ok, %{id: id}} = Pears.add_team(name)
    assert {:ok, %{name: ^name}} = Pears.get_team(id)
    assert {:error, :not_found} = Pears.get_team("bad-id")
  end

  test "teams can be removed", %{name: name} do
    {:ok, _} = Pears.add_team(name)
    {:ok, _} = Pears.lookup_team_by_name(name)
    {:ok, _} = Pears.remove_team(name)
    {:error, _} = Pears.lookup_team_by_name(name)
    {:error, _} = Pears.get_unsaved_team(name)
  end

  test "cannot add pair to non-existent track or non-existent pear", %{name: name} do
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
