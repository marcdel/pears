defmodule TeamBuilders do
  alias Pears.Core.Team

  def team do
    Team.new(name: "Team #{random_id()}")
  end

  def with(team, pears: pear_count, tracks: track_count) do
    Enum.reduce(1..pear_count, team, fn _, team ->
      Team.add_pear(team, "pear#{random_id()}")
    end)

    Enum.reduce(1..track_count, team, fn _, team ->
      Team.add_track(team, "track#{random_id()}")
    end)
  end

  defp random_id do
    Enum.random(1..1_000)
  end
end
