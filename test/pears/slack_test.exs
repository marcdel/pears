defmodule Pears.SlackTest do
  use Pears.DataCase, async: true

  alias Pears.Slack

  setup [:team]

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"

  defmodule FakeSlackClient do
    @valid_token_response %{
      "access_token" => "xoxp-XXXXXXXX-XXXXXXXX-XXXXX",
      "app_id" => "XXXXXXXXXX",
      "authed_user" => %{"id" => "UTTTTTTTTTTL"},
      "bot_user_id" => "UTTTTTTTTTTR",
      "enterprise" => nil,
      "ok" => true,
      "response_metadata" => %{"warnings" => ["superfluous_charset"]},
      "scope" =>
        "commands,chat:write,app_mentions:read,channels:read,im:read,im:write,im:history,users:read",
      "team" => %{"id" => "XXXXXXXXXX", "name" => "Team Installing Your Hook"},
      "token_type" => "bot",
      "warning" => "superfluous_charset"
    }

    def retrieve_access_tokens(code) do
      send(self(), {:code, code})
      @valid_token_response
    end
  end

  describe "onboard_team" do
    test "exchanges a code for an access token and saves it in the session", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, FakeSlackClient)
      assert Slack.token(team.name) == "xoxp-XXXXXXXX-XXXXXXXX-XXXXX"
    end
  end

  defp team(_) do
    {:ok, team} = Pears.add_team("test team")
    {:ok, team: team}
  end
end
