defmodule Pears.SlackClientTest do
  use ExUnit.Case, async: true

  alias Pears.SlackClient

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @valid_token "a98edabf0cf97010a115ef264771a1f98c"
  @redirect_uri "https://fake.com/slack/oauth"

  test "calls slack oauth access method with the provided code" do
    fake_access_fn = fn _, _, code, %{redirect_uri: redirect_uri} ->
      send(self(), {:oauth_access, code, redirect_uri})
    end

    SlackClient.retrieve_access_tokens(@valid_code, @redirect_uri, fake_access_fn)

    assert_receive {:oauth_access, code, redirect_uri}
    assert code == @valid_code
    assert redirect_uri == @redirect_uri
  end

  test "can get the list of channels for a given token" do
    fake_channels_fn = fn %{token: token, next_cursor: next_cursor} ->
      send(self(), {:fetch_channels, token, next_cursor})
    end

    SlackClient.channels(@valid_token, "", fake_channels_fn)

    assert_receive {:fetch_channels, token, ""}
    assert token == @valid_token
  end

  test "can send a message to the specified channel" do
    fake_message_fn = fn channel, text, %{token: token} ->
      send(self(), {:message, channel, text, token})
    end

    SlackClient.send_message("general", "Hiiii!!", @valid_token, fake_message_fn)

    assert_receive {:message, "general", "Hiiii!!", token}
    assert token == @valid_token
  end
end
