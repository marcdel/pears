defmodule Pears do
  @moduledoc """
  Pears allows users to create teams, add pairs and tracks of work, and then assign
  pairs to those tracks of work. It can recommend pairings for pairs that haven't
  been assigned to a track.
  """
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamManager
  alias Pears.Boundary.TeamSession
  alias Pears.Core.Recommendator
  alias Pears.Core.Team
  alias Pears.Persistence

  @topic inspect(__MODULE__)

  @decorate trace("pears.subscribe", include: [:team_name])
  def subscribe(team_name) do
    Phoenix.PubSub.subscribe(Pears.PubSub, @topic <> "#{team_name}")
    {:ok, team_name}
  end

  @decorate trace("pears.validate_name", include: [:team_name])
  def validate_name(team_name) do
    with :ok <- TeamManager.validate_name(team_name),
         {:error, :not_found} <- Persistence.get_team_by_name(team_name) do
      :ok
    else
      {:error, validation_error} ->
        {:error, validation_error}

      {:ok, _team_record} ->
        {:error, :name_taken}
    end
  end

  @decorate trace("pears.add_team", include: [:team_name, :error])
  def add_team(team_name) do
    with team_name <- String.trim(team_name),
         :ok <- TeamManager.validate_name(team_name),
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

  @decorate trace("pears.lookup_team_by", include: [:team_name])
  def lookup_team_by(name: team_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, team} <- update_subscribers(team) do
      {:ok, team}
    end
  end

  @decorate trace("pears.remove_team", include: [:team_name])
  def remove_team(team_name) do
    Persistence.delete_team(team_name)
    TeamSession.end_session(team_name)
    TeamManager.remove_team(team_name)
  end

  @decorate trace("pears.add_pear", include: [:team_name, :pear_name, :error])
  def add_pear(team_name, pear_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, pear_record} <- Persistence.add_pear_to_team(team_name, pear_name),
         updated_team <-
           Team.add_pear(team, pear_name,
             id: pear_record.id,
             slack_name: pear_record.slack_name,
             slack_id: pear_record.slack_id
           ),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.remove_pear", include: [:team_name, :pear_name, :error])
  def remove_pear(team_name, pear_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _pear} <- validate_pear_on_team(team, pear_name),
         {:ok, _pear_record} <- Persistence.remove_pear_from_team(team_name, pear_name),
         updated_team <- Team.remove_pear(team, pear_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.add_track", include: [:team_name, :track_name, :error])
  def add_track(team_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, track_record} <- Persistence.add_track_to_team(team_name, track_name),
         updated_team <- Team.add_track(team, track_name, track_record.id),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.remove_track", include: [:team_name, :track_name, :error])
  def remove_track(team_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         {:ok, _track_record} <- Persistence.remove_track_from_team(team_name, track_name),
         updated_team <- Team.remove_track(team, track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.lock_track", include: [:team_name, :track_name])
  def lock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, true)

  @decorate trace("pears.unlock_track", include: [:team_name, :track_name])
  def unlock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, false)

  @decorate trace("pears.rename_track",
              include: [:team_name, :track_name, :new_track_name, :error]
            )
  def rename_track(team_name, track_name, new_track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         {:ok, _track_record} <- Persistence.rename_track(team.name, track_name, new_track_name),
         updated_team <- Team.rename_track(team, track_name, new_track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.toggle_track_locked",
              include: [:team_name, :track_name, :locked?, :error]
            )
  def toggle_track_locked(team_name, track_name, locked?) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         {:ok, updated_team} <- lock_or_unlock_track(team, track_name, locked?),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.toggle_anchor", include: [:team_name, :pear_name, :track_name])
  def toggle_anchor(team_name, pear_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _pear} <- validate_pear_on_team(team, pear_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         _pear <- Persistence.toggle_anchor(team_name, pear_name, track_name),
         updated_team <- Team.toggle_anchor(team, pear_name, track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.lock_or_unlock_track",
              include: [:team_name, :track_name, :locked?, :error]
            )
  defp lock_or_unlock_track(%{name: team_name} = team, track_name, true) do
    with {:ok, _track_record} <- Persistence.lock_track(team_name, track_name),
         updated_team <- Team.lock_track(team, track_name) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.lock_or_unlock_track",
              include: [:team_name, :track_name, :locked?, :error]
            )
  defp lock_or_unlock_track(%{name: team_name} = team, track_name, false) do
    with {:ok, _track_record} <- Persistence.unlock_track(team_name, track_name),
         updated_team <- Team.unlock_track(team, track_name) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.add_pear_to_track",
              include: [:team_name, :pear_name, :track_name, :error]
            )
  def add_pear_to_track(team_name, pear_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _pear} <- validate_pear_available(team, pear_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         updated_team <- Team.add_pear_to_track(team, pear_name, track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.add_pear_to_track", include: [:team_name, :pear_name, :track_name])
  def move_pear_to_track(team_name, pear_name, nil = _from_track_name, track_name) do
    add_pear_to_track(team_name, pear_name, track_name)
  end

  @decorate trace(
              "pears.move_pear_to_track",
              include: [:team_name, :pear_name, :from_track_name, :to_track_name, :error]
            )
  def move_pear_to_track(team_name, pear_name, from_track_name, to_track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _pear} <- validate_pear_on_team(team, pear_name),
         {:ok, _from_track} <- validate_track_exists(team, from_track_name),
         {:ok, _to_track} <- validate_track_exists(team, to_track_name),
         updated_team <- Team.move_pear_to_track(team, pear_name, from_track_name, to_track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.remove_pear_from_track",
              include: [:team_name, :pear_name, :track_name, :error]
            )
  def remove_pear_from_track(team_name, pear_name, track_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         {:ok, _pear} <- validate_pear_assigned(team, pear_name),
         {:ok, _track} <- validate_track_exists(team, track_name),
         updated_team <- Team.remove_pear_from_track(team, pear_name, track_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.recommend_pears", include: [:team_name, :result])
  def recommend_pears(team_name) do
    with {:ok, team_with_history} <- TeamSession.find_or_start_session(team_name),
         team_with_empty_tracks <- maybe_add_empty_tracks(team_with_history),
         updated_team <- assign_pears(team_with_empty_tracks),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  defp assign_pears(team) do
    if FeatureFlags.enabled?(:new_suggest_function, for: team) do
      Recommendator.choose_anchors_and_suggest(team)
    else
      Recommendator.assign_pears(team)
    end
  end

  @decorate trace("pears.reset_pears", include: [:team_name, :error])
  def reset_pears(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         updated_team <- Team.reset_matches(team),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.record_pears", include: [:team_name, :error])
  def record_pears(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         updated_team <- Team.record_pears(team),
         {:ok, updated_team} <- persist_changes(updated_team),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team),
         {:ok, updated_team} <- update_subscribers(updated_team) do
      {:ok, updated_team}
    else
      error -> error
    end
  end

  @decorate trace("pears.add_pears_to_tracks", include: [:team_name, :snapshot])
  def add_pears_to_tracks(team_name, snapshot) do
    Enum.each(snapshot, fn match ->
      [track_name, pear_names] = Tuple.to_list(match)
      Enum.each(pear_names, &Persistence.add_pear_to_track(team_name, &1, track_name))
    end)
  end

  @decorate trace("pears.facilitator", include: [:team_name, :result])
  def facilitator(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         true <- Team.has_active_pears?(team) do
      TeamSession.facilitator(team_name)
    else
      false -> {:error, :no_pears}
      error -> error
    end
  end

  @decorate trace("pears.new_facilitator", include: [:team_name, :result])
  def new_facilitator(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         true <- Team.has_active_pears?(team) do
      TeamSession.new_facilitator(team_name)
    else
      false -> {:error, :no_pears}
      error -> error
    end
  end

  @decorate trace("pears.has_active_pears?", include: [:team_name, :result])
  def has_active_pears?(team_name) do
    with {:ok, team} <- TeamSession.get_team(team_name),
         has_active_pears <- Team.has_active_pears?(team) do
      has_active_pears
    else
      _ -> false
    end
  end

  @decorate trace("pears.validate_pear_available", include: [[:team, :name], :pear_name])
  defp validate_pear_available(team, pear_name) do
    case Team.find_available_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  @decorate trace("pears.validate_pear_assigned", include: [[:team, :name], :pear_name])
  defp validate_pear_assigned(team, pear_name) do
    case Team.find_assigned_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  @decorate trace("pears.validate_pear_on_team", include: [[:team, :name], :pear_name])
  defp validate_pear_on_team(team, pear_name) do
    case Team.find_pear(team, pear_name) do
      %{name: ^pear_name} = pear -> {:ok, pear}
      nil -> {:error, :not_found}
    end
  end

  @decorate trace("pears.validate_track_exists", include: [[:team, :name], :track_name])
  defp validate_track_exists(team, track_name) do
    case Team.find_track(team, track_name) do
      %{name: ^track_name} = track -> {:ok, track}
      nil -> {:error, :not_found}
    end
  end

  @decorate trace(
              "pears.maybe_add_empty_tracks",
              include: [
                :team,
                :available_slots,
                :available_pears,
                :pears_without_track,
                :number_to_add
              ]
            )
  defp maybe_add_empty_tracks(team) do
    available_slots = Team.available_slot_count(team)
    available_pears = Enum.count(team.available_pears)
    pears_without_track = available_pears - available_slots
    number_to_add = ceil(pears_without_track / 2)

    add_empty_tracks(team, number_to_add)
  end

  @decorate trace("pears.add_empty_tracks", include: [[:team, :name], :count])
  defp add_empty_tracks(team, count)

  defp add_empty_tracks(team, count) when count <= 0, do: team

  defp add_empty_tracks(team, count) do
    Enum.reduce(1..count, team, fn i, team ->
      case add_track(team.name, "Untitled Track #{i}") do
        {:ok, team} -> team
        {:error, _} -> team
      end
    end)
  end

  @decorate trace("pears.persist_changes", include: [[:team, :name], :snapshot, :error])
  defp persist_changes(team) do
    snapshot = Team.current_matches(team)

    with {:ok, _team_record} <- Persistence.add_snapshot_to_team(team.name, snapshot),
         :ok <- add_pears_to_tracks(team.name, snapshot) do
      {:ok, team}
    else
      error -> error
    end
  end

  @decorate trace("pears.update_subscribers", include: [[:team, :name]])
  defp update_subscribers(team) do
    topic = @topic <> "#{team.name}"
    Phoenix.PubSub.broadcast(Pears.PubSub, topic, {__MODULE__, [:team, :updated], team})
    {:ok, team}
  end
end
