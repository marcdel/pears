defmodule Pears.Slack.Messages.DailyPairsMessageTest do
  use ExUnit.Case, async: true

  alias Pears.Core.Team
  alias Pears.Slack.Messages.DailyPairsMessage

  setup [:team]

  describe "new/1" do
    test "returns a message with a list of pairs", %{team: team} do
      team =
        team
        |> Team.add_track("track1")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "track1")
        |> Team.add_pear_to_track("pear2", "track1")
        |> Team.add_track("track2")
        |> Team.add_pear("pear3")
        |> Team.add_pear("pear4")
        |> Team.add_pear_to_track("pear3", "track2")
        |> Team.add_pear_to_track("pear4", "track2")

      {:ok, message} = DailyPairsMessage.new(team)

      assert lines(message) == [
               "Today's 🍐s are:",
               "- pear1 & pear2 on track1",
               "- pear3 & pear4 on track2"
             ]
    end

    test "does not include empty tracks", %{team: team} do
      team =
        team
        |> Team.add_track("track1")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "track1")
        |> Team.add_pear_to_track("pear2", "track1")
        |> Team.add_track("track2")

      {:ok, message} = DailyPairsMessage.new(team)

      assert lines(message) == [
               "Today's 🍐s are:",
               "- pear1 & pear2 on track1"
             ]
    end

    test "does not include available pears", %{team: team} do
      team =
        team
        |> Team.add_track("track1")
        |> Team.add_pear("pear1")
        |> Team.add_pear("pear2")
        |> Team.add_pear_to_track("pear1", "track1")

      {:ok, message} = DailyPairsMessage.new(team)

      assert lines(message) == [
               "Today's 🍐s are:",
               "- pear1 on track1"
             ]
    end
  end

  defp team(_) do
    {:ok, team: Team.new(name: "test team")}
  end

  defp lines(message) do
    message
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end
end
