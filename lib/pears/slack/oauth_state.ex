defmodule Pears.Slack.OAuthState do
  @moduledoc """
  Generates and verifies the OAuth `state` token that protects the Slack
  onboarding callback against CSRF.
  """

  def generate do
    Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
  end

  def valid?(expected, provided) when is_binary(expected) and is_binary(provided) do
    Plug.Crypto.secure_compare(expected, provided)
  end

  def valid?(_expected, _provided), do: false
end
