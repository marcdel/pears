defmodule Pears.Persistence do
  @moduledoc """
  The Persistence context.
  """
  use Pears.O11y.Decorator

  import Ecto.Query, warn: false

  alias Pears.Repo
  alias Pears.Persistence.{PearRecord, SnapshotRecord, TeamRecord, TrackRecord}

  @decorate trace_decorator([:persistence, :create_team], [:team_name])
  def create_team(team_name) do
    %TeamRecord{}
    |> TeamRecord.changeset(%{name: team_name})
    |> Repo.insert()
  end

  @decorate trace_decorator([:persistence, :delete_team], [:team_name])
  def delete_team(team_name) do
    case get_team_by_name(team_name) do
      {:error, :not_found} -> nil
      {:ok, team} -> Repo.delete(team)
    end
  end

  @decorate trace_decorator([:persistence, :get_team_by_name], [:team_name, :team])
  def get_team_by_name(team_name) do
    result =
      TeamRecord
      |> Repo.get_by(name: team_name)
      |> Repo.preload([
        {:pears, :track},
        {:tracks, :pears},
        {:snapshots, :matches},
        snapshots: from(s in SnapshotRecord, order_by: [desc: s.inserted_at])
      ])

    case result do
      nil -> {:error, :not_found}
      team -> {:ok, team}
    end
  end

  def count_teams do
    Repo.aggregate(TeamRecord, :count, :id)
  end

  @decorate trace_decorator([:persistence, :find_track_by_name], [:team, :track_name, :track])
  def find_track_by_name(team, track_name) do
    case Enum.find(team.tracks, fn track -> track.name == track_name end) do
      nil -> {:error, :track_not_found}
      track -> {:ok, track}
    end
  end

  @decorate trace_decorator([:persistence, :find_pear_by_name], [:team, :pear_name, :pear])
  def find_pear_by_name(team, pear_name) do
    case Enum.find(team.pears, fn pear -> pear.name == pear_name end) do
      nil -> {:error, :pear_not_found}
      pear -> {:ok, pear}
    end
  end

  @decorate trace_decorator(
              [:persistence, :add_pear_to_team],
              [:team_name, :pear_name, :team, :pear, :error]
            )
  def add_pear_to_team(team_name, pear_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, pear} <- add_pear(team, pear_name) do
      {:ok, pear}
    else
      error -> error
    end
  end

  @decorate trace_decorator([:persistence, :add_pear], [:team, :pear_name, :pear, :error])
  defp add_pear(team, pear_name) do
    case %PearRecord{}
         |> PearRecord.changeset(%{team_id: team.id, name: pear_name})
         |> Repo.insert() do
      {:ok, pear} -> {:ok, Repo.preload(pear, [:track])}
      error -> error
    end
  end

  @decorate trace_decorator(
              [:persistence, :add_pear_to_track],
              [:team, :pear_name, :track_name, :error]
            )
  def add_pear_to_track(team_name, pear_name, track_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- find_track_by_name(team, track_name),
         {:ok, pear} <- find_pear_by_name(team, pear_name),
         {:ok, _} <- do_add_pear_to_track(pear, track) do
      {:ok, pear}
    else
      error -> error
    end
  end

  @decorate trace_decorator([:persistence, :do_add_pear_to_track], [:pear, :track])
  def do_add_pear_to_track(pear, track) do
    pear
    |> Repo.preload(:track)
    |> PearRecord.changeset(%{track_id: track.id})
    |> Repo.update()
  end

  @decorate trace_decorator(
              [:persistence, :add_track_to_team],
              [:team_name, :track_name, :track, :error]
            )
  def add_track_to_team(team_name, track_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- add_track(team, track_name) do
      {:ok, track}
    else
      error -> error
    end
  end

  @decorate trace_decorator([:persistence, :add_track], [:team, :track_name, :track, :error])
  defp add_track(team, track_name) do
    case %TrackRecord{}
         |> TrackRecord.changeset(%{team_id: team.id, name: track_name, locked: false})
         |> Repo.insert() do
      {:ok, track} -> {:ok, Repo.preload(track, [:pears])}
      error -> error
    end
  end

  @decorate trace_decorator([:persistence, :lock_track], [:team, :track_name])
  def lock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, true)

  @decorate trace_decorator([:persistence, :unlock_track], [:team, :track_name])
  def unlock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, false)

  defp toggle_track_locked(team_name, track_name, locked?) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- find_track_by_name(team, track_name),
         {:ok, track} <- do_toggle_track_locked(track, locked?) do
      {:ok, track}
    else
      error -> error
    end
  end

  @decorate trace_decorator(
              [:persistence, :rename_track],
              [:team_name, :track_name, :new_track_name, :updated_track, :error]
            )
  def rename_track(team_name, track_name, new_track_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- find_track_by_name(team, track_name),
         {:ok, updated_track} <- do_rename_track(track, new_track_name) do
      {:ok, updated_track}
    else
      error -> error
    end
  end

  @decorate trace_decorator([:persistence, :do_rename_track], [:track, :new_track_name])
  defp do_rename_track(track, new_track_name) do
    track
    |> TrackRecord.changeset(%{name: new_track_name})
    |> Repo.update()
  end

  defp do_toggle_track_locked(track, locked?) do
    track
    |> TrackRecord.changeset(%{locked: locked?})
    |> Repo.update()
  end

  @decorate trace_decorator(
              [:persistence, :remove_track_from_team],
              [:team_name, :track_name, :team, :error]
            )
  def remove_track_from_team(team_name, track_name) do
    case get_team_by_name(team_name) do
      {:ok, team} ->
        track = Repo.get_by(TrackRecord, team_id: team.id, name: track_name)
        Repo.delete(track)

      error ->
        error
    end
  end

  @decorate trace_decorator(
              [:persistence, :add_snapshot_to_team],
              [:team_name, :snapshot, :snapshot_record, :error]
            )
  def add_snapshot_to_team(team_name, snapshot) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, snapshot_record} <- save_snapshot(team, snapshot) do
      {:ok, snapshot_record}
    else
      error -> error
    end
  end

  defp save_snapshot(team, snapshot) do
    %SnapshotRecord{}
    |> SnapshotRecord.changeset(%{
      team_id: team.id,
      matches: build_matches(snapshot)
    })
    |> Repo.insert()
  end

  defp build_matches(snapshot) do
    Enum.map(snapshot, &build_match/1)
  end

  defp build_match({track_name, pear_names}) do
    %{track_name: track_name, pear_names: pear_names}
  end
end
