defmodule Pears.SlackClientTest do
  use ExUnit.Case, async: true

  alias Pears.SlackClient

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"

  def fake_access_fn(_, _, code) do
    send(self(), {:code, code})
  end

  test "calls slack oauth access method with the provided code" do
    SlackClient.retrieve_access_tokens(@valid_code, &fake_access_fn/3)

    assert_receive {:code, code}
    assert code == @valid_code
  end
end
