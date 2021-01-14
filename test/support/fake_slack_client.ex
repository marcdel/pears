defmodule FakeSlackClient do
  @moduledoc """
    Implements the SlackClient behaviour with sensible default responses

    Example usage:

    setup do
      stub_with(MockSlackClient, FakeSlackClient)
      :ok
    end
  """

  alias Pears.SlackFixtures

  @behaviour Pears.SlackClient.Behaviour

  def retrieve_access_tokens(_code, _url) do
    SlackFixtures.valid_token_response()
  end

  def channels(token, cursor, list_conversations \\ &Conversations.list/1) do
    %{}
  end

  def users(token, cursor, list_users \\ &Users.list/1) do
    %{}
  end

  def send_message(channel, text, token, post_chat_message) when is_binary(text) do
    %{}
  end

  def send_message(channel, blocks, token, post_chat_message) when is_list(blocks) do
    %{}
  end

  def find_or_create_group_chat(users, token, open_conversation \\ &Conversations.open/1) do
    %{}
  end
end
