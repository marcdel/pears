defmodule Pears do
  @moduledoc """
  Pears allows users to create teams, add pairs and tracks of work, and then assign
  pairs to those tracks of work. It can recommend pairings for pairs that haven't
  been assigned to a track.
  """

  alias Pears.Boundary.{TeamManager, TeamSession}
  alias Pears.Persistence
  alias Pears.Core.Team
  alias Pears.Core.Recommendator

  @topic inspect(__MODULE__)

  def subscribe(team_name) do
    Phoenix.PubSub.subscribe(Pears.PubSub, @topic <> "#{team_name}")
  end

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
    Persistence.delete_team(name)
    TeamSession.end_session(name)
    TeamManager.remove_team(name)
  end

  def add_pear(team_name, pear_name) do
    with {:ok, _} <- Persistence.add_pear_to_team(team_name, pear_name),
         {:ok, team} <- TeamSession.add_pear(team_name, pear_name),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def add_track(team_name, track_name) do
    with {:ok, _} <- Persistence.add_track_to_team(team_name, track_name),
         {:ok, team} <- TeamSession.add_track(team_name, track_name),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def remove_track(team_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_track_exists(team, track_name),
         {:ok, _} <- Persistence.remove_track_from_team(team_name, track_name),
         {:ok, team} <- TeamSession.remove_track(team_name, track_name),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def lock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, true)
  def unlock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, false)

  def rename_track(team_name, track_name, new_track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_track_exists(team, track_name),
         {:ok, _} <- Persistence.rename_track(team.name, track_name, new_track_name),
         team <- Team.rename_track(team, track_name, new_track_name),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def toggle_track_locked(team_name, track_name, locked?) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_track_exists(team, track_name),
         {:ok, team} <- lock_or_unlock_track(team, track_name, locked?),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  defp lock_or_unlock_track(team, track_name, true) do
    with {:ok, _} <- Persistence.lock_track(team.name, track_name),
         team <- Team.lock_track(team, track_name) do
      {:ok, team}
    else
      error -> error
    end
  end

  defp lock_or_unlock_track(team, track_name, false) do
    with {:ok, _} <- Persistence.unlock_track(team.name, track_name),
         team <- Team.unlock_track(team, track_name) do
      {:ok, team}
    else
      error -> error
    end
  end

  def add_pear_to_track(team_name, pear_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_pear_available(team, pear_name),
         {:ok, _} <- validate_track_exists(team, track_name),
         team <- Team.add_pear_to_track(team, pear_name, track_name),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def move_pear_to_track(team_name, pear_name, nil, to_track_name) do
    add_pear_to_track(team_name, pear_name, to_track_name)
  end

  def move_pear_to_track(team_name, pear_name, from_track_name, to_track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_pear_on_team(team, pear_name),
         {:ok, _} <- validate_track_exists(team, from_track_name),
         {:ok, _} <- validate_track_exists(team, to_track_name),
         team <- Team.move_pear_to_track(team, pear_name, from_track_name, to_track_name),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def remove_pear_from_track(team_name, pear_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _} <- validate_pear_assigned(team, pear_name),
         {:ok, _} <- validate_track_exists(team, track_name),
         team <- Team.remove_pear_from_track(team, pear_name, track_name),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def recommend_pears(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         team <- maybe_add_empty_tracks(team),
         team <- Recommendator.assign_pears(team),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def reset_pears(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         team <- Team.reset_matches(team),
         {:ok, team} <- TeamSession.update_team(team_name, team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def record_pears(team_name) do
    with {:ok, team} <- TeamSession.record_pears(team_name),
         {:ok, team} <- persist_changes(team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def lookup_team_by(name: name) do
    with {:ok, team} <- maybe_fetch_team_from_db(name),
         {:ok, team} <- get_or_start_session(team),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    else
      error -> error
    end
  end

  def add_pears_to_tracks(team_name, snapshot) do
    Enum.each(snapshot, fn match ->
      [track_name, pear_names] = Tuple.to_list(match)
      Enum.each(pear_names, &Persistence.add_pear_to_track(team_name, &1, track_name))
    end)
  end

  defp validate_pear_available(team, pear_name) do
    case Team.find_available_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  defp validate_pear_assigned(team, pear_name) do
    case Team.find_assigned_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  defp validate_pear_on_team(team, pear_name) do
    case Team.find_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  defp validate_track_exists(team, track_name) do
    case Team.find_track(team, track_name) do
      %{name: ^track_name} = track -> {:ok, track}
      nil -> {:error, :not_found}
    end
  end

  defp maybe_add_empty_tracks(team) do
    available_slots = Team.available_slot_count(team)
    available_pears = Enum.count(team.available_pears)
    pears_without_track = available_pears - available_slots
    number_to_add = ceil(pears_without_track / 2)

    add_empty_tracks(team, number_to_add)
  end

  defp add_empty_tracks(team, count) when count <= 0, do: team

  defp add_empty_tracks(team, count) do
    Enum.reduce(1..count, team, fn i, team ->
      case add_track(team.name, "Untitled Track #{i}") do
        {:ok, team} -> team
        {:error, _} -> team
      end
    end)
  end

  defp maybe_fetch_team_from_db(team_name) do
    case TeamManager.lookup_team_by_name(team_name) do
      {:ok, team} ->
        {:ok, team}

      {:error, :not_found} ->
        fetch_team_from_db(team_name)
    end
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
    |> assign_pears(team_record)
    |> add_history(team_record)
  end

  defp add_pears(team, team_record) do
    Enum.reduce(team_record.pears, team, fn pear_record, team ->
      Team.add_pear(team, pear_record.name)
    end)
  end

  defp add_tracks(team, team_record) do
    Enum.reduce(team_record.tracks, team, fn track_record, team ->
      team
      |> Team.add_track(track_record.name)
      |> maybe_lock_track(track_record)
    end)
  end

  defp assign_pears(team, team_record) do
    Enum.reduce(team_record.pears, team, fn pear_record, team ->
      case pear_record.track do
        nil -> team
        _ -> Team.add_pear_to_track(team, pear_record.name, pear_record.track.name)
      end
    end)
  end

  defp maybe_lock_track(team, %{locked: false}), do: team

  defp maybe_lock_track(team, %{locked: true, name: track_name}) do
    Team.lock_track(team, track_name)
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

    with {:ok, _} <- Persistence.add_snapshot_to_team(team.name, snapshot),
         :ok <- add_pears_to_tracks(team.name, snapshot) do
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

  defp update_subscribers(team) do
    Phoenix.PubSub.broadcast(
      Pears.PubSub,
      @topic <> "#{team.name}",
      {__MODULE__, [:team, :updated], team}
    )

    {:ok, team}
  end
end
