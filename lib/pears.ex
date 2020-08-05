defmodule Pears do
  @moduledoc """
  Pears allows users to create teams, add pairs and tracks of work, and then assign
  pairs to those tracks of work. It can recommend pairings for pairs that haven't
  been assigned to a track.
  """

  alias Pears.Boundary.{TeamManager, TeamSession}
  alias Pears.Persistence
  alias Pears.Core.Team

  def validate_name(team_name) do
    with :ok <- TeamManager.validate_name(team_name),
         {:error, :not_found} <- Persistence.get_team_by_name(team_name) do
      :ok
    else
      _ -> {:error, :name_taken}
    end
  end

  def add_team(team_name) do
    with :ok <- TeamManager.validate_name(team_name),
         {:ok, _team_record} <- Persistence.create_team(team_name),
         {:ok, team} <- TeamManager.add_team(team_name),
         {:ok, team} <- TeamSession.start_session(team) do
      {:ok, team}
    else
      {:error, error} ->
        {:error, error}

      error ->
        {:error, error}
    end
  end

  def remove_team(name) do
    case Persistence.delete_team(name) do
      {:ok, _} ->
        TeamSession.end_session(name)
        TeamManager.remove_team(name)

      error ->
        error
    end
  end

  def add_pear(team_name, pear_name) do
    with {:ok, _} <- Persistence.add_pear_to_team(team_name, pear_name),
         {:ok, team} <- TeamSession.add_pear(team_name, pear_name) do
      {:ok, team}
    else
      error -> error
    end
  end

  def add_track(team_name, track_name) do
    with {:ok, _} <- Persistence.add_track_to_team(team_name, track_name),
         {:ok, team} <- TeamSession.add_track(team_name, track_name) do
      {:ok, team}
    else
      error -> error
    end
  end

  def remove_track(team_name, track_name) do
    with {:ok, _} <- Persistence.remove_track_from_team(team_name, track_name),
         {:ok, team} <- TeamSession.remove_track(team_name, track_name) do
      {:ok, team}
    else
      error -> error
    end
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

  def make_pear_unavailable(team_name, pear_name) do
    TeamSession.make_pear_unavailable(team_name, pear_name)
  end

  def recommend_pears(team_name) do
    TeamSession.recommend_pears(team_name)
  end

  def record_pears(team_name) do
    with {:ok, team} <- TeamSession.record_pears(team_name),
         {:ok, team} <- persist_changes(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def lookup_team_by(name: name) do
    with {:ok, team} <- maybe_fetch_team_from_db(name),
         {:ok, team} <- get_or_start_session(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def maybe_fetch_team_from_db(team_name) do
    case TeamManager.lookup_team_by_name(team_name) do
      {:ok, team} ->
        {:ok, team}

      {:error, :not_found} ->
        fetch_team_from_db(team_name)
    end
  end

  def import_history_from_parrit_json(team_name, json) do
    grouped_by_date =
      json
      |> Jason.decode!()
      |> Enum.group_by(fn match_json ->
        Map.get(match_json, "pairingTime")
      end)

    grouped_by_date
    |> Map.keys()
    |> Enum.sort(:desc)
    |> Enum.each(fn date ->
      snapshot =
        grouped_by_date
        |> Map.get(date)
        |> Enum.map(fn match_json ->
          track_name = Map.get(match_json, "pairingBoardName")

          pear_names =
            match_json
            |> Map.get("people")
            |> Enum.map(&Map.get(&1, "name"))

          {track_name, pear_names}
        end)

      {:ok, _} = Persistence.add_snapshot_to_team(team_name, snapshot)

      snapshot
    end)

    TeamManager.remove_team(team_name)
    TeamSession.end_session(team_name)

    {:ok, team} = lookup_team_by(name: team_name)

    team
  end

  defp fetch_team_from_db(team_name) do
    case Persistence.get_team_by_name(team_name) do
      {:ok, team_record} ->
        {:ok, map_to_team(team_record)}

      error ->
        error
    end
  end

  defp map_to_team(team_record) do
    Team.new(name: team_record.name)
    |> add_pears(team_record)
    |> add_tracks(team_record)
    |> add_history(team_record)
    |> Team.assign_pears_from_history()
  end

  defp add_pears(team, team_record) do
    Enum.reduce(team_record.pears, team, fn pear_record, team ->
      Team.add_pear(team, pear_record.name)
    end)
  end

  defp add_tracks(team, team_record) do
    Enum.reduce(team_record.tracks, team, fn track_record, team ->
      Team.add_track(team, track_record.name)
    end)
  end

  defp add_history(team, team_record) do
    history =
      Enum.map(team_record.snapshots, fn snapshot ->
        Enum.map(snapshot.matches, fn %{track_name: track_name, pear_names: pear_names} ->
          {track_name, pear_names}
        end)
      end)

    Map.put(team, :history, history)
  end

  defp persist_changes(team) do
    snapshot = Team.current_matches(team)

    case Persistence.add_snapshot_to_team(team.name, snapshot) do
      {:ok, _} -> {:ok, team}
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
