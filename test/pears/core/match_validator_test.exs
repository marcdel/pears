defmodule Pears.Core.MatchValidatorTest do
  use ExUnit.Case, async: true

  alias Pears.Core.{MatchValidator, Team}

  describe "a solo match" do
    test "is valid when the pear is available and an empty unlocked track exists" do
      team =
        TeamBuilders.team()
        |> Team.add_track("empty track")
        |> Team.add_pear("pear1")

      assert MatchValidator.valid?({"pear1"}, team) == true
    end

    test "is invalid when no track is empty" do
      team =
        TeamBuilders.team()
        |> Team.add_track("incomplete track")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "incomplete track")

      assert MatchValidator.valid?({"pear2"}, team) == false
    end

    test "is invalid when the only empty track is locked" do
      team =
        TeamBuilders.team()
        |> Team.add_track("locked track")
        |> Team.lock_track("locked track")
        |> Team.add_pear("pear1")

      assert MatchValidator.valid?({"pear1"}, team) == false
    end

    test "is invalid when the pear is already assigned" do
      team =
        TeamBuilders.team()
        |> Team.add_track("track1")
        |> Team.add_track("track2")
        |> Team.add_pear("pear1")
        |> Team.add_pear_to_track("pear1", "track1")

      assert MatchValidator.valid?({"pear1"}, team) == false
    end
  end

  describe "a pair match" do
    test "is valid when both pears are available and an empty track exists" do
      team =
        TeamBuilders.team()
        |> Team.add_track("empty track")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")

      assert MatchValidator.valid?({"pear1", "pear2"}, team) == true
    end

    test "is invalid when both pears are available but no track is empty" do
      team =
        TeamBuilders.team()
        |> Team.add_track("full track")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear("pear3")
        |> Team.add_pear("pear4")
        |> Team.add_pear_to_track("pear1", "full track")
        |> Team.add_pear_to_track("pear2", "full track")

      assert MatchValidator.valid?({"pear3", "pear4"}, team) == false
    end

    test "is valid when one pear can join the other's incomplete track" do
      team =
        TeamBuilders.team()
        |> Team.add_track("incomplete track")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "incomplete track")

      assert MatchValidator.valid?({"pear2", "pear1"}, team) == true
    end

    test "is invalid when the other pear's track is already full, even if an empty track exists" do
      team =
        TeamBuilders.team()
        |> Team.add_track("full track")
        |> Team.add_track("empty track")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear("pear3")
        |> Team.add_pear_to_track("pear1", "full track")
        |> Team.add_pear_to_track("pear2", "full track")

      assert MatchValidator.valid?({"pear3", "pear1"}, team) == false
    end

    test "is invalid when neither pear is available" do
      team =
        TeamBuilders.team()
        |> Team.add_track("track1")
        |> Team.add_track("track2")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "track1")
        |> Team.add_pear_to_track("pear2", "track2")

      assert MatchValidator.valid?({"pear1", "pear2"}, team) == false
    end
  end
end
