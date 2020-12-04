defmodule Pears.SlackClient do
  use OpenTelemetryDecorator

  alias Slack.Web.Chat, as: Chat
  alias Slack.Web.Conversations, as: Conversations
  alias Slack.Web.Oauth.V2, as: Auth

  @decorate trace("slack_client.retrieve_access_tokens")
  def retrieve_access_tokens(code, oauth_access \\ &Auth.access/3) do
    oauth_access.(client_id(), client_secret(), code)
  end

  @decorate trace("slack_client.channels")
  def channels(token, list_conversations \\ &Conversations.list/1) do
    list_conversations.(%{token: token})
  end

  @decorate trace("slack_client.send_message")
  def send_message(channel, text, token, post_chat_message \\ &Chat.post_message/3) do
    post_chat_message.(channel, text, %{token: token})
  end

  defp client_id, do: Application.fetch_env!(:pears, :slack_client_id)
  defp client_secret, do: Application.fetch_env!(:pears, :slack_client_secret)
end