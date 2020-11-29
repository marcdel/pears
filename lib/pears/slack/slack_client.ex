defmodule Pears.SlackClient do
  use OpenTelemetryDecorator
  alias Slack.Web.Oauth.V2, as: Auth

  @decorate trace("slack_client.retrieve_access_tokens")
  def retrieve_access_tokens(code, oauth_access \\ &Auth.access/3) do
    oauth_access.(client_id(), client_secret(), code)
  end

  defp client_id, do: Application.fetch_env!(:pears, :slack_client_id)
  defp client_secret, do: Application.fetch_env!(:pears, :slack_client_secret)
end
