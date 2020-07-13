defmodule Pears do
  @moduledoc """
  Pears allows users to create teams, add pairs and tracks of work, and then assign
  pairs to those tracks of work. It can recommend pairings for pairs that haven't
  been assigned to a track.
  """

  alias Pears.Boundary.{TeamManager, TeamSession}

  def validate_name(team_name) do
    TeamManager.validate_name(team_name)
  end

  def add_team(team_name) do
    with :ok <- TeamManager.validate_name(team_name),
         {:ok, team} <- TeamManager.add_team(team_name),
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
    TeamSession.end_session(name)
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

  def get_team(team_id) do
    TeamManager.lookup_team_by_id(team_id)
  end

  def get_team_session(team_name) do
    with true <- TeamSession.session_started?(team_name),
         {:ok, team} <- TeamSession.get_team(team_name) do
      {:ok, team}
    else
      false -> {:error, :no_session}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def lookup_team_by_name(team_name) do
    TeamManager.lookup_team_by_name(team_name)
  end
end
