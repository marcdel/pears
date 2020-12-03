defmodule Pears.SlackTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
  alias Pears.Slack

  setup [:team]

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @invalid_code "asljaskjasdaskda"

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

  @invalid_token_response %{
    "error" => "invalid_code",
    "ok" => false,
    "response_metadata" => %{"warnings" => ["superfluous_charset"]},
    "warning" => "superfluous_charset"
  }

  @valid_conversations_response %{
    "channels" => [
      %{
        "created" => 123_456_789,
        "creator" => "UTTTTTTTTTTL",
        "id" => "XXXXXXXXXX",
        "is_archived" => false,
        "is_channel" => true,
        "is_ext_shared" => false,
        "is_general" => true,
        "is_group" => false,
        "is_im" => false,
        "is_member" => false,
        "is_mpim" => false,
        "is_org_shared" => false,
        "is_pending_ext_shared" => false,
        "is_private" => false,
        "is_shared" => false,
        "name" => "general",
        "name_normalized" => "general",
        "num_members" => 1,
        "parent_conversation" => nil,
        "pending_connected_team_ids" => [],
        "pending_shared" => [],
        "previous_names" => [],
        "purpose" => %{
          "creator" => "",
          "last_set" => 0,
          "value" =>
            "This channel is for team-wide communication and announcements. All team members are in this channel."
        },
        "shared_team_ids" => ["XXXXXXXXXX"],
        "topic" => %{
          "creator" => "",
          "last_set" => 0,
          "value" => "Company-wide announcements and work-based matters"
        },
        "unlinked" => 0
      }
    ],
    "ok" => true,
    "response_metadata" => %{
      "next_cursor" => "",
      "warnings" => ["superfluous_charset"]
    },
    "warning" => "superfluous_charset"
  }

  @invalid_conversations_response %{
    "error" => "not_authed",
    "ok" => false,
    "response_metadata" => %{"warnings" => ["superfluous_charset"]},
    "warning" => "superfluous_charset"
  }

  def retrieve_access_tokens(code) do
    send(self(), {:code, code})

    case code do
      @valid_code -> @valid_token_response
      @invalid_code -> @invalid_token_response
    end
  end

  def channels(token) do
    case token do
      nil -> @invalid_conversations_response
      _ -> @valid_conversations_response
    end
  end

  describe "onboard_team" do
    test "exchanges a code for an access token and saves it", %{team: team} do
      {:ok, team} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      assert team.slack_token == "xoxp-XXXXXXXX-XXXXXXXX-XXXXX"

      {:ok, team_record} = Persistence.get_team_by_name(team.name)
      assert team_record.slack_token == "xoxp-XXXXXXXX-XXXXXXXX-XXXXX"
    end

    test "handles invalid responses", %{team: team} do
      {:error, _} = Slack.onboard_team(team.name, @invalid_code, __MODULE__)
    end
  end

  describe "get_details" do
    setup %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      :ok
    end

    test "exchanges a code for an access token and saves it in the session", %{team: team} do
      {:ok, details} = Slack.get_details(team.name, __MODULE__)
      assert [%{name: "general"}] = details.channels
    end

    test "handles invalid responses" do
      {:ok, _} = Pears.add_team("no token")
      assert {:error, :no_token} = Slack.get_details("no token", __MODULE__)
    end

    test "returns the team's slack_channel", %{team: team} do
      {:ok, _} = Slack.save_team_channel(team.name, "cool team")

      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      assert details.team_channel == "cool team"
    end
  end

  describe "save_team_channel" do
    test "sets the team slack_channel to the provided channel name", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      {:ok, team} = Slack.save_team_channel(team.name, "random")

      assert team.slack_channel == "random"

      {:ok, team_record} = Persistence.get_team_by_name(team.name)
      assert team_record.slack_channel == "random"
    end
  end

  defp team(_) do
    {:ok, team} = Pears.add_team(Ecto.UUID.generate())
    {:ok, team: team}
  end
end
