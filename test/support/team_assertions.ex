defmodule TeamAssertions do
  import ExUnit.Assertions
  alias Pears.Core.{Team, Track}

  def assert_pear_in_track(team, pear_name, track_name) do
    assert pear_in_track?(team, pear_name, track_name)
    team
  end

  def refute_pear_in_track(team, pear_name, track_name) do
    refute pear_in_track?(team, pear_name, track_name)
    team
  end

  def assert_pear_available(team, pear_name) do
    assert Team.pear_available?(team, pear_name)
    team
  end

  def refute_pear_available(team, pear_name) do
    refute Team.pear_available?(team, pear_name)
    team
  end

  def assert_track_exists(team, track_name) do
    assert track_exists?(team, track_name)
    team
  end

  def refute_track_exists(team, track_name) do
    refute track_exists?(team, track_name)
    team
  end

  def assert_track_locked(team, track_name) do
    assert track_locked?(team, track_name)
    team
  end

  def refute_track_locked(team, track_name) do
    refute track_locked?(team, track_name)
    team
  end

  def assert_anchoring_track(team, pear_name, track_name) do
    assert Team.find_track(team, track_name).anchor == pear_name
    team
  end

  def refute_anchoring_track(team, pear_name, track_name) do
    refute Team.find_track(team, track_name).anchor == pear_name
    team
  end

  def refute_history(team, expected_history) do
    refute histrories_are_equal?(team, expected_history)
    team
  end

  def assert_history(team, expected_history) do
    assert histrories_are_equal?(team, expected_history)
    team
  end

  def histrories_are_equal?(team, expected_history) do
    team.history == expected_history
  end

  def track_exists?(team, track_name) do
    Team.find_track(team, track_name) != nil
  end

  def track_locked?(team, track_name) do
    team
    |> Team.find_track(track_name)
    |> Track.locked?()
  end

  def pear_available?(team, pear_name) do
    Team.pear_available?(team, pear_name)
  end

  def pear_in_track?(team, pear_name, track_name) do
    track = Team.find_track(team, track_name)
    pear = Team.find_assigned_pear(team, pear_name)
    Track.find_pear(track, pear_name) != nil && pear.track == track_name
  end

  def assert_pear_order(team, "available", expected_order) do
    actual_order =
      team.available_pears
      |> Map.values()
      |> Enum.map(fn pear -> {pear.order, pear.name} end)
      |> Enum.sort_by(fn {order, _} -> order end)
      |> Enum.map(fn {_, name} -> name end)

    assert actual_order == expected_order

    team
  end

  def assert_pear_order(team, track, expected_order) do
    actual_order =
      team.tracks
      |> Map.get(track)
      |> Map.get(:pears)
      |> Map.values()
      |> Enum.map(fn pear -> {pear.order, pear.name} end)
      |> Enum.sort_by(fn {order, _} -> order end)
      |> Enum.map(fn {_, name} -> name end)

    assert actual_order == expected_order

    team
  end

  def assert_has_active_pears(team) do
    assert Team.has_active_pears?(team)

    team
  end

  def refute_has_active_pears(team) do
    refute Team.has_active_pears?(team)

    team
  end
end
