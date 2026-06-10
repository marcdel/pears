defmodule Pears.Slack.OAuthStateTest do
  use ExUnit.Case, async: true

  alias Pears.Slack.OAuthState

  describe "generate/0" do
    test "returns a url-safe token" do
      token = OAuthState.generate()

      assert is_binary(token)
      assert {:ok, _} = Base.url_decode64(token, padding: false)
    end

    test "returns a different token each time" do
      assert OAuthState.generate() != OAuthState.generate()
    end
  end

  describe "valid?/2" do
    test "returns true when the provided state matches the expected state" do
      state = OAuthState.generate()

      assert OAuthState.valid?(state, state)
    end

    test "returns false when the provided state does not match" do
      refute OAuthState.valid?(OAuthState.generate(), OAuthState.generate())
      refute OAuthState.valid?(OAuthState.generate(), "onboard")
    end

    test "returns false when either state is missing" do
      refute OAuthState.valid?(nil, OAuthState.generate())
      refute OAuthState.valid?(OAuthState.generate(), nil)
      refute OAuthState.valid?(nil, nil)
    end
  end
end
