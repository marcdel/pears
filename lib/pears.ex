defmodule Pears do
  @moduledoc """
  Pears allows users to create teams, add pairs and tracks of work, and then assign
  pairs to those tracks of work. It can recommend pairings for pairs that haven't
  been assigned to a track.
  """

  alias Pears.Boundary.{TeamManager, TeamSession}

  def add_team(team_name) do
    with {:ok, team} <- TeamManager.add_team(team_name),
         {:ok, _} <- TeamSession.start_session(team) do
      {:ok, team}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def persist_changes(team_name) do
    {:ok, team} = TeamSession.get_team(team_name)
    TeamManager.update_team(team)
  end

  def remove_team(name) do
    TeamManager.remove_team(name)
  end

  def add_pear(team_name, pear_name) do
    TeamSession.add_pear(team_name, pear_name)
  end

  def add_track(team_name, track_name) do
    TeamSession.add_track(team_name, track_name)
  end

  def add_pear_to_track(team_name, pear_name, track_name) do
    TeamSession.add_pear_to_track(team_name, pear_name, track_name)
  end

  def recommend_pears(team_name) do
    TeamSession.recommend_pears(team_name)
  end

  def get_unsaved_team(team_name) do
    TeamSession.get_team(team_name)
  end

  def lookup_team_by_name(team_name) do
    TeamManager.lookup_team_by_name(team_name)
  end
end
