defmodule Pears.Slack.Messages.EndOfSessionQuestionTest do
  use ExUnit.Case, async: true
  alias Pears.Core.Pear
  alias Pears.Core.Track
  alias Pears.Slack.Messages.EndOfSessionQuestion

  setup do
    track =
      Track.new(name: "Feature 1")
      |> Track.add_pear(Pear.new(name: "Pear 1"))
      |> Track.add_pear(Pear.new(name: "Pear 2"))

    {:ok, track: track}
  end

  describe "new/1" do
    test "returns a list of blocks", %{track: track} do
      message = EndOfSessionQuestion.new(track)
      assert is_list(message)
    end

    test "adds an action for each pear in the track", %{track: track} do
      message = EndOfSessionQuestion.new(track)

      assert find_button(message, "Pear 1") != nil
      assert find_button(message, "Pear 2") != nil
    end
  end

  defp find_button(blocks, button_text) do
    blocks
    |> Enum.find(fn block -> Map.get(block, "type") == "actions" end)
    |> Map.get("elements")
    |> Enum.find(fn block -> get_in(block, ["text", "text"]) == button_text end)
  end
end
