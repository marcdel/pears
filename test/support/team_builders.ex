defmodule TeamBuilders do
  alias Pears.Core.Team

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
