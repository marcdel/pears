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
         {:ok, team} <- TeamSession.start_session(team) do
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

  def remove_track(team_name, track_name) do
    TeamSession.remove_track(team_name, track_name)
  end

  def add_pear_to_track(team_name, pear_name, track_name) do
    TeamSession.add_pear_to_track(team_name, pear_name, track_name)
  end

  def move_pear_to_track(team_name, pear_name, from_track_name, to_track_name) do
    TeamSession.move_pear_to_track(team_name, pear_name, from_track_name, to_track_name)
  end

  def remove_pear_from_track(team_name, pear_name, track_name) do
    TeamSession.remove_pear_from_track(team_name, pear_name, track_name)
  end

  def recommend_pears(team_name) do
    TeamSession.recommend_pears(team_name)
  end

  def lookup_team_by(id: id) do
    with {:ok, team} <- TeamManager.lookup_team_by_id(id),
         {:ok, team} <- get_or_start_session(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def lookup_team_by(name: name) do
    with {:ok, team} <- TeamManager.lookup_team_by_name(name),
         {:ok, team} <- get_or_start_session(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  defp get_or_start_session(team) do
    get_or_start_session(team, session_started?: TeamSession.session_started?(team.name))
  end

  defp get_or_start_session(team, session_started?: false) do
    TeamSession.start_session(team)
  end

  defp get_or_start_session(%{name: team_name}, session_started?: true) do
    TeamSession.get_team(team_name)
  end
end
