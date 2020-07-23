defmodule Pears.Persistence do
  @moduledoc """
  The Persistence context.
  """

  import Ecto.Query, warn: false

  alias Pears.Repo
  alias Pears.Persistence.{PearRecord, TeamRecord, TrackRecord}

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
      |> Repo.preload([:pears, :tracks])

    case result do
      nil -> {:error, :not_found}
      team -> {:ok, team}
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
    %PearRecord{}
    |> PearRecord.changeset(%{team_id: team.id, name: pear_name})
    |> Repo.insert()
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
    %TrackRecord{}
    |> TrackRecord.changeset(%{team_id: team.id, name: track_name})
    |> Repo.insert()
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
end
