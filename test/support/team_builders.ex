defmodule TeamBuilders do
  alias Pears.Core.Team
  alias Pears.Persistence

  def create_team(name \\ "Team #{Ecto.UUID.generate()}") do
    {:ok, team} = Persistence.create_team(name)
    team
  end

  def create_teams(count) do
    Enum.map(1..count, fn _ -> create_team() end)
  end

  def create_pears(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, pear} = Persistence.add_pear_to_team(team.name, "Pear #{Ecto.UUID.generate()}")
      pear
    end)
  end

  def create_tracks(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, pear} = Persistence.add_track_to_team(team.name, "Track #{Ecto.UUID.generate()}")
      pear
    end)
  end

  def create_snapshots(team, count) do
    Enum.map(1..count, fn _ ->
      {:ok, snapshot} =
        Persistence.add_snapshot_to_team(team.name, [{"track one", ["pear1", "pear2"]}])

      snapshot
    end)
  end

  def create_matches(team, count) do
    Persistence.add_snapshot_to_team(
      team.name,
      Enum.map(1..count, fn _ ->
        {"Track #{Ecto.UUID.generate()}",
         ["Track #{Ecto.UUID.generate()}", "Track #{Ecto.UUID.generate()}"]}
      end)
    )
  end

  def create_tokens(team, count) do
    Enum.map(1..count, fn _ ->
      Pears.Accounts.generate_team_session_token(team)
    end)
  end

  def team do
    Team.new(name: "Team #{random_id()}")
  end

  def from_matches(matches) do
    Enum.reduce(matches, team(), fn
      {pear1, pear2, track}, team ->
        team
        |> Team.add_track(track)
        |> Team.add_pear(pear1)
        |> Team.add_pear(pear2)
        |> Team.add_pear_to_track(pear1, track)
        |> Team.add_pear_to_track(pear2, track)

      {pear1, track}, team ->
        team
        |> Team.add_track(track)
        |> Team.add_pear(pear1)
        |> Team.add_pear_to_track(pear1, track)

      {pear1}, team ->
        Team.add_pear(team, pear1)

      pear1, team ->
        Team.add_pear(team, pear1)
    end)
    |> Team.record_pears()
  end

  defp random_id do
    Enum.random(1..1_000)
  end
end
