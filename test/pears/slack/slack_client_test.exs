defmodule Pears.SlackClientTest do
  use ExUnit.Case, async: true

  alias Pears.SlackClient

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @valid_token "a98edabf0cf97010a115ef264771a1f98c"
  @redirect_uri "https://fake.com/slack/oauth"

  test "calls slack oauth access method with the provided code" do
    retrieve_access_tokens =
      Hammox.protect({SlackClient, :retrieve_access_tokens, 3}, SlackClient.Behaviour)

    fake_access_fn = fn _, _, code, %{redirect_uri: redirect_uri} ->
      send(self(), {:oauth_access, code, redirect_uri})
      %{"ok" => true}
    end

    retrieve_access_tokens.(@valid_code, @redirect_uri, fake_access_fn)

    assert_receive {:oauth_access, code, redirect_uri}
    assert code == @valid_code
    assert redirect_uri == @redirect_uri
  end

  test "can get the list of channels for a given token" do
    channels = Hammox.protect({SlackClient, :channels, 3}, SlackClient.Behaviour)

    fake_channels_fn = fn %{token: token, cursor: cursor} ->
      send(self(), {:fetch_channels, token, cursor})
      %{"ok" => true}
    end

    channels.(@valid_token, "", fake_channels_fn)

    assert_receive {:fetch_channels, token, ""}
    assert token == @valid_token
  end

  test "can get the list of users for a given token" do
    users = Hammox.protect({SlackClient, :users, 3}, SlackClient.Behaviour)

    fake_users_fn = fn %{token: token, cursor: cursor} ->
      send(self(), {:fetch_users, token, cursor})
      %{"ok" => true}
    end

    users.(@valid_token, "", fake_users_fn)

    assert_receive {:fetch_users, token, ""}
    assert token == @valid_token
  end

  test "can send a message to the specified channel" do
    send_message = Hammox.protect({SlackClient, :send_message, 4}, SlackClient.Behaviour)

    fake_message_fn = fn channel, text, %{token: token} ->
      send(self(), {:message, channel, text, token})
      %{"ok" => true}
    end

    SlackClient.send_message("general", "Hiiii!!", @valid_token, fake_message_fn)

    assert_receive {:message, "general", "Hiiii!!", token}
    assert token == @valid_token
  end

  test "can send a message with blocks to the specified channel" do
    send_message = Hammox.protect({SlackClient, :send_message, 4}, SlackClient.Behaviour)

    fake_message_fn = fn channel, text, %{token: token, blocks: blocks_json} ->
      send(self(), {:message, channel, text, blocks_json, token})
      %{"ok" => true}
    end

    blocks = [
      %{
        "type" => "section",
        "text" => %{
          "type" => "mrkdwn",
          "text" => "Hello, *user*!"
        }
      }
    ]

    send_message.("USER1", blocks, @valid_token, fake_message_fn)

    assert_receive {:message, "USER1", text, blocks_json, token}

    assert text == "A message from the Pears app..."

    assert blocks_json ==
             "[{\"text\":{\"text\":\"Hello, *user*!\",\"type\":\"mrkdwn\"},\"type\":\"section\"}]"

    assert token == @valid_token
  end

  test "can open a chat message between pears bot and multiple users" do
    find_or_create_group_chat =
      Hammox.protect({SlackClient, :find_or_create_group_chat, 3}, SlackClient.Behaviour)

    fake_open_fn = fn %{users: users, token: token} ->
      send(self(), {:open_chat, users, token})
      %{"ok" => true}
    end

    find_or_create_group_chat.(["USER1", "USER2"], @valid_token, fake_open_fn)

    assert_receive {:open_chat, "USER1,USER2", token}
    assert token == @valid_token
  end
end
