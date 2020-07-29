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
    Team.find_track(team, track_name)
  end

  def pear_available?(team, pear_name) do
    Team.pear_available?(team, pear_name)
  end

  def pear_in_track?(team, pear_name, track_name) do
    track = Team.find_track(team, track_name)
    Track.find_pear(track, pear_name)
  end
end
