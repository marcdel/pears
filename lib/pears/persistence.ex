defmodule Pears.Persistence do
  @moduledoc """
  The Persistence context.
  """

  import Ecto.Query, warn: false

  alias Pears.Repo
  alias Pears.Persistence.{PearRecord, TeamRecord, TrackRecord}

  def create_team(team) do
    %TeamRecord{}
    |> TeamRecord.changeset(%{name: team.name})
    |> Repo.insert()
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

  def add_pear_to_team(team, pear_name) do
    %PearRecord{}
    |> PearRecord.changeset(%{team_id: team.id, name: pear_name})
    |> Repo.insert()
  end

  def add_track_to_team(team, track_name) do
    %TrackRecord{}
    |> TrackRecord.changeset(%{team_id: team.id, name: track_name})
    |> Repo.insert()
  end

  def remove_track_from_team(team, track_name) do
    track = Repo.get_by(TrackRecord, team_id: team.id, name: track_name)
    Repo.delete(track)
  end
end
