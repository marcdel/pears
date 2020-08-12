defmodule ImportHistory do
  alias Pears.Persistence
  alias Pears.Boundary.TeamManager
  alias Pears.Boundary.TeamSession

  def add_latest_tracks_and_import do
    name = "team name"
    Pears.add_team(name)
    Pears.add_pear(name, "Pear 1")
    Pears.add_track(name, "Track 1")

    json = ~s([])

    import_history_from_parrit_json(name, json)
  end

  def import_history_from_parrit_json(team_name, json) do
    grouped_by_date =
      json
      |> Jason.decode!()
      |> Enum.group_by(fn match_json ->
        Map.get(match_json, "pairingTime")
      end)

    history =
      grouped_by_date
      |> Map.keys()
      |> Enum.sort(:desc)
      |> Enum.map(fn date ->
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

    Pears.add_pears_to_tracks(team_name, List.first(history))

    TeamManager.remove_team(team_name)
    TeamSession.end_session(team_name)

    {:ok, team} = Pears.lookup_team_by(name: team_name)

    team
  end
end
