defmodule Pears.Core.RecommendatorTest do
  use ExUnit.Case, async: true

  import TeamAssertions
  alias Pears.Core.{Team, Recommendator}

  test "does not modify team when there are no unassigned pears" do
    before_team =
      TeamBuilders.team()
      |> TeamBuilders.with(pears: 4, tracks: 2)

    after_team = Recommendator.assign_pears(before_team)

    assert after_team == before_team
  end

  test "given one pear and one track, moves pear to track" do
    TeamBuilders.team()
    |> Team.add_track("feature track")
    |> Team.add_pear("pear1")
    |> Recommendator.assign_pears()
    |> assert_pear_in_track("pear1", "feature track")
  end
end
