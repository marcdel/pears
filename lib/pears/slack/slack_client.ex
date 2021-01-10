defmodule Pears.SlackClient do
  use OpenTelemetryDecorator

  alias Slack.Web.Chat, as: Chat
  alias Slack.Web.Conversations, as: Conversations
  alias Slack.Web.Oauth.V2, as: Auth
  alias Slack.Web.Users, as: Users

  @decorate trace("slack_client.retrieve_access_tokens")
  def retrieve_access_tokens(code, redirect_uri, oauth_access \\ &Auth.access/4) do
    oauth_access.(client_id(), client_secret(), code, %{redirect_uri: redirect_uri})
  end

  @decorate trace("slack_client.channels")
  def channels(token, cursor, list_conversations \\ &Conversations.list/1) do
    list_conversations.(%{token: token, cursor: cursor})
  end

  @decorate trace("slack_client.users")
  def users(token, cursor, list_users \\ &Users.list/1) do
    list_users.(%{token: token, cursor: cursor})
  end

  def send_message(channel, text, token, post_chat_message \\ &Chat.post_message/3)

  @decorate trace("slack_client.send_message")
  def send_message(channel, text, token, post_chat_message) when is_binary(text) do
    post_chat_message.(channel, text, %{token: token})
  end

  @decorate trace("slack_client.send_message")
  def send_message(channel, blocks, token, post_chat_message) when is_list(blocks) do
    post_chat_message.(channel, "A message from the Pears app...", %{
      blocks: Jason.encode!(blocks),
      token: token
    })
  end

  @decorate trace("slack_client.find_or_create_group_chat")
  def find_or_create_group_chat(users, token, open_conversation \\ &Conversations.open/1) do
    open_conversation.(%{users: Enum.join(users, ","), token: token})
  end

  defp client_id, do: Application.fetch_env!(:pears, :slack_client_id)
  defp client_secret, do: Application.fetch_env!(:pears, :slack_client_secret)
end
