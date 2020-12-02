defmodule Pears.SlackClientTest do
  use ExUnit.Case, async: true

  alias Pears.SlackClient

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @valid_token "a98edabf0cf97010a115ef264771a1f98c"

  test "calls slack oauth access method with the provided code" do
    fake_access_fn = fn _, _, code -> send(self(), {:code, code}) end

    SlackClient.retrieve_access_tokens(@valid_code, fake_access_fn)

    assert_receive {:code, code}
    assert code == @valid_code
  end

  test "can get the list of channels for a given token" do
    fake_channels_fn = fn %{token: token} -> send(self(), {:token, token}) end

    SlackClient.channels(@valid_token, fake_channels_fn)

    assert_receive {:token, token}
    assert token == @valid_token
  end
end
