defmodule Pears.Persistence do
  @moduledoc """
  The Persistence context.
  """

  import Ecto.Query, warn: false

  alias Pears.Repo
  alias Pears.Persistence.{PearRecord, SnapshotRecord, TeamRecord, TrackRecord}

  def create_team(team_name) do
    %TeamRecord{}
    |> TeamRecord.changeset(%{name: team_name})
    |> Repo.insert()
  end

  def delete_team(team_name) do
    case get_team_by_name(team_name) do
      {:error, :not_found} -> nil
      {:ok, team} -> Repo.delete(team)
    end
  end

  def get_team_by_name(team_name) do
    result =
      TeamRecord
      |> Repo.get_by(name: team_name)
      |> Repo.preload([{:pears, :track}, {:tracks, :pears}, {:snapshots, :matches}])

    case result do
      nil -> {:error, :not_found}
      team -> {:ok, team}
    end
  end

  def count_teams do
    Repo.aggregate(TeamRecord, :count, :id)
  end

  def find_track_by_name(team, track_name) do
    case Enum.find(team.tracks, fn track -> track.name == track_name end) do
      nil -> {:error, :track_not_found}
      track -> {:ok, track}
    end
  end

  def find_pear_by_name(team, pear_name) do
    case Enum.find(team.pears, fn pear -> pear.name == pear_name end) do
      nil -> {:error, :pear_not_found}
      pear -> {:ok, pear}
    end
  end

  def add_pear_to_team(team_name, pear_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, pear} <- add_pear(team, pear_name) do
      {:ok, pear}
    else
      error -> error
    end
  end

  defp add_pear(team, pear_name) do
    case %PearRecord{}
         |> PearRecord.changeset(%{team_id: team.id, name: pear_name})
         |> Repo.insert() do
      {:ok, pear} -> {:ok, Repo.preload(pear, [:track])}
      error -> error
    end
  end

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

  def do_add_pear_to_track(pear, track) do
    pear
    |> Repo.preload(:track)
    |> PearRecord.changeset(%{track_id: track.id})
    |> Repo.update()
  end

  def add_track_to_team(team_name, track_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- add_track(team, track_name) do
      {:ok, track}
    else
      error -> error
    end
  end

  defp add_track(team, track_name) do
    case %TrackRecord{}
         |> TrackRecord.changeset(%{team_id: team.id, name: track_name, locked: false})
         |> Repo.insert() do
      {:ok, track} -> {:ok, Repo.preload(track, [:pears])}
      error -> error
    end
  end

  def lock_track(team_name, track_name), do: toggle_track_locked(team_name, track_name, true)
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

  def rename_track(team_name, track_name, new_track_name) do
    with {:ok, team} <- get_team_by_name(team_name),
         {:ok, track} <- find_track_by_name(team, track_name),
         {:ok, track} <- do_rename_track(track, new_track_name) do
      {:ok, track}
    else
      error -> error
    end
  end

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

  def remove_track_from_team(team_name, track_name) do
    case get_team_by_name(team_name) do
      {:ok, team} ->
        track = Repo.get_by(TrackRecord, team_id: team.id, name: track_name)
        Repo.delete(track)

      error ->
        error
    end
  end

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
