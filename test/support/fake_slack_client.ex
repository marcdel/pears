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

  defp no_op, do: nil

  def retrieve_access_tokens(_code, _url, _get_tokens \\ no_op()) do
    SlackFixtures.valid_token_response()
  end

  def channels(_token, _cursor, _list_conversations \\ no_op()) do
    SlackFixtures.conversations_response(page: 2)
  end

  def users(_token, _cursor, _list_users \\ no_op()) do
    SlackFixtures.list_users_response(2)
  end

  def send_message(_channel, _text, _token, _post_chat_message \\ no_op()) do
    %{}
  end

  def find_or_create_group_chat(_users, _token, _open_conversation \\ no_op()) do
    %{}
  end
end
