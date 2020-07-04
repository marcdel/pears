defmodule Pears.Core.TeamTest do
  use ExUnit.Case, async: true

  alias Pears.Core.{Pear, Team}

  setup [:team]

  test "can add a pear to the team", %{team: team} do
    pear1 = Pear.new(name: "pear1")
    team = Team.add_pear(team, pear1)
    assert team.pears == [pear1]

    pear2 = Pear.new(name: "pear2")
    team = Team.add_pear(team, pear2)
    assert team.pears == [pear2, pear1]
  end

  defp team(_) do
    {:ok, team: Team.new(name: "test team")}
  end
end
