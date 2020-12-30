defmodule Pears.SlackTest do
  use Pears.DataCase, async: true

  alias Pears.Persistence
  alias Pears.Slack
  alias Pears.Slack.Details
  alias Pears.SlackFixtures

  setup [:team]

  @valid_code "169403114024.1535385215366.e6118897ed25c4e0d78803d3217ac7a98edabf0cf97010a115ef264771a1f98c"
  @invalid_code "asljaskjasdaskda"

  @valid_token "xoxb-XXXXXXXX-XXXXXXXX-XXXXX"
  @valid_user_token "xoxp-XXXXXXXX-XXXXXXXX-XXXXX"

  @valid_token_response %{
    "access_token" => @valid_token,
    "app_id" => "XXXXXXXXXX",
    "authed_user" => %{
      "access_token" => @valid_user_token,
      "id" => "UTTTTTTTTTTL",
      "scope" => "search:read",
      "token_type" => "user"
    },
    "bot_user_id" => "UTTTTTTTTTTR",
    "enterprise" => nil,
    "ok" => true,
    "response_metadata" => %{"warnings" => ["superfluous_charset"]},
    "scope" =>
      "commands,chat:write,app_mentions:read,channels:read,im:read,im:write,im:history,users:read,chat:write.public",
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

  @conversations_page_one %{
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
        "name" => "random",
        "name_normalized" => "random",
        "num_members" => 1,
        "parent_conversation" => nil,
        "pending_connected_team_ids" => [],
        "pending_shared" => [],
        "previous_names" => [],
        "purpose" => %{
          "creator" => "",
          "last_set" => 0,
          "value" =>
            "A place for non-work-related flimflam, faffing, hodge-podge or jibber-jabber you'd prefer to keep out of more focused work-related channels."
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
      "next_cursor" => "page_two",
      "warnings" => ["superfluous_charset"]
    },
    "warning" => "superfluous_charset"
  }

  @conversations_page_two %{
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

  @users_page_one SlackFixtures.list_users_response(1)
  @users_page_two SlackFixtures.list_users_response(2)

  @valid_open_chat_response SlackFixtures.open_chat_response(id: "GROUPCHATID")

  def retrieve_access_tokens(code, _redirect_uri) do
    case code do
      @valid_code -> @valid_token_response
      @invalid_code -> @invalid_token_response
    end
  end

  describe "onboard_team" do
    test "exchanges a code for an access token and saves it", %{team: team} do
      {:ok, team} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      assert team.slack_token == @valid_token

      {:ok, team_record} = Persistence.get_team_by_name(team.name)
      assert team_record.slack_token == @valid_token
    end

    test "handles invalid responses", %{team: team} do
      {:error, _} = Slack.onboard_team(team.name, @invalid_code, __MODULE__)
    end
  end

  def channels(nil, _next_cursor), do: @invalid_conversations_response
  def channels(_token, ""), do: @conversations_page_one
  def channels(_token, _next_cursor), do: @conversations_page_two

  def users(_token, ""), do: @users_page_one
  def users(_token, _next_cursor), do: @users_page_two

  describe "get_details" do
    setup %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      :ok
    end

    test "returns a list of all channels in the slack organization", %{team: team} do
      {:ok, details} = Slack.get_details(team.name, __MODULE__)
      assert [%{name: "general"}, %{name: "random"}] = details.channels
    end

    test "returns a list of all users in the slack organization", %{team: team} do
      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      assert [%{id: "XXXXXXXXXX", name: "marc"}, %{id: "YYYYYYYYYY", name: "milo"}] =
               details.users
    end

    test "returns a list of all pears in the team and their slack details", %{team: team} do
      {:ok, team} = Pears.add_pear(team.name, "marc")
      {:ok, team} = Pears.add_pear(team.name, "milo")

      Persistence.add_pear_slack_details(team.name, "milo", %{
        slack_id: "XXXXXXXXXX",
        slack_name: "miloooooo"
      })

      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      assert [
               %{slack_id: nil, slack_name: nil, name: "marc"},
               %{slack_id: "XXXXXXXXXX", slack_name: "miloooooo", name: "milo"}
             ] = details.pears
    end

    test "handles invalid responses" do
      {:ok, _} = Pears.add_team("no token")
      assert {:error, details} = Slack.get_details("no token", __MODULE__)
      assert details == Details.empty()
      {:ok, _} = Pears.remove_team("no token")
    end

    test "returns the team's slack_channel", %{team: team} do
      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "cool team"})

      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      assert details.team_channel == %{id: "UXXXXXXX", name: "cool team"}
    end
  end

  describe "save_team_channel" do
    test "sets the team slack_channel to the provided channel", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      {:ok, updated_details} =
        Slack.save_team_channel(details, team.name, %{id: "UXXXXXXX", name: "random"})

      assert updated_details.team_channel == %{id: "UXXXXXXX", name: "random"}

      {:ok, team_record} = Persistence.get_team_by_name(team.name)
      assert team_record.slack_channel_id == "UXXXXXXX"
      assert team_record.slack_channel_name == "random"
    end
  end

  describe "save_slack_names" do
    test "saves the slack id and slack name for each pear", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      {:ok, _} = Pears.add_pear(team.name, "Marc")
      {:ok, _} = Pears.add_pear(team.name, "Milo")
      {:ok, _} = Pears.add_pear(team.name, "Jackie")
      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      params = %{"Marc" => "XXXXXXXXXX", "Milo" => "YYYYYYYYYY", "Jackie" => ""}

      {:ok, updated_details} = Slack.save_slack_names(details, team.name, params)

      {:ok, team_record} = Persistence.get_team_by_name(team.name)

      returned_pears =
        updated_details.pears
        |> Enum.sort_by(&Map.get(&1, :name))
        |> Enum.map(fn pear -> {pear.name, pear.slack_id, pear.slack_name} end)

      updated_pears =
        team_record
        |> Map.get(:pears)
        |> Enum.sort_by(&Map.get(&1, :name))
        |> Enum.map(fn pear -> {pear.name, pear.slack_id, pear.slack_name} end)

      assert returned_pears == updated_pears

      assert updated_pears == [
               {"Jackie", nil, nil},
               {"Marc", "XXXXXXXXXX", "marc"},
               {"Milo", "YYYYYYYYYY", "milo"}
             ]
    end
  end

  def send_message(channel, text, token) when is_binary(text) do
    send(self(), {:send_message, channel, text, token})

    case channel do
      nil -> %{"ok" => false}
      _ -> %{"ok" => true}
    end
  end

  def send_message(channel, blocks, token) when is_list(blocks) do
    send(self(), {:send_message, channel, blocks, token})

    case channel do
      nil -> %{"ok" => false}
      _ -> %{"ok" => true}
    end
  end

  describe "send_message_to_team" do
    setup %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      :ok
    end

    test "sends a message to the team's slack channel", %{team: team} do
      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "random"})

      message = "Hey, friends!"

      {:ok, ^message} = Slack.send_message_to_team(team.name, message, __MODULE__)

      assert_receive {:send_message, "UXXXXXXX", message, token}
      assert token == @valid_token
    end

    test "handles invalid responses", %{team: team} do
      # Invalid because we haven't set the team channel
      {:error, _} = Slack.send_message_to_team(team.name, "Hey, friends!", __MODULE__)
      refute_receive {:send_message, _, _, _}
    end
  end

  describe "send_daily_pears_summary" do
    setup [:four_pears_two_tracks]

    setup %{team: team} do
      FeatureFlags.enable(:send_daily_pears_summary, for_actor: team)
      :ok
    end

    test "sends a summary of who is pairing on what", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "random"})

      {:ok, _} = Slack.send_daily_pears_summary(team.name, __MODULE__)

      assert_receive {:send_message, "UXXXXXXX", message, _}

      assert message == """
             Today's 🍐s are:
             \t- Pear One & Pear Two on Track One
             \t- Pear Four & Pear Three on Track Two
             """
    end

    test "does not send a message if feature turned off", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)

      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "random"})

      FeatureFlags.disable(:send_daily_pears_summary, for_actor: team)

      Slack.send_daily_pears_summary(team.name, __MODULE__)

      refute_receive {:send_message, _, _, _}
    end

    test "does not send a message if no channel is specified", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      {:error, _} = Slack.send_daily_pears_summary(team.name)
      refute_receive {:send_message, _, _, _}
    end

    test "does not send a message if no token is saved", %{team: team} do
      {:error, _} = Slack.send_daily_pears_summary(team.name)
      refute_receive {:send_message, _, _, _}
    end
  end

  def find_or_create_group_chat(users, token) do
    send(self(), {:open_chat, users, token})
    @valid_open_chat_response
  end

  describe "send_end_of_session_questions" do
    setup %{team: team} do
      FeatureFlags.enable(:send_end_of_session_questions, for_actor: team)
      {:ok, _} = Slack.onboard_team(team.name, @valid_code, __MODULE__)
      :ok
    end

    test "sends a message to each set of pears", %{team: team} do
      {:ok, _} = Pears.add_pear(team.name, "Marc")
      {:ok, _} = Pears.add_pear(team.name, "Milo")
      {:ok, _} = Pears.add_track(team.name, "Feature 1")
      {:ok, _} = Pears.add_pear_to_track(team.name, "Marc", "Feature 1")
      {:ok, _} = Pears.add_pear_to_track(team.name, "Milo", "Feature 1")
      {:ok, details} = Slack.get_details(team.name, __MODULE__)

      params = %{"Marc" => "XXXXXXXXXX", "Milo" => "YYYYYYYYYY"}
      {:ok, _} = Slack.save_slack_names(details, team.name, params)

      {:ok, _} = Slack.send_end_of_session_questions(team.name, __MODULE__)

      assert_receive {:open_chat, ["XXXXXXXXXX", "YYYYYYYYYY"], token}
      assert token == @valid_token

      assert_receive {:send_message, "GROUPCHATID", blocks, token}
      assert token == @valid_token

      assert blocks == [
               %{
                 "text" => %{
                   "text" =>
                     "Hey, friends! 👋\n\nTo make tomorrow's standup even smoother, I wanted to check whether you've decided who would like to continue working on your current track (Feature 1) and who will rotate to another track.",
                   "type" => "mrkdwn"
                 },
                 "type" => "section"
               },
               %{"type" => "divider"},
               %{
                 "text" => %{
                   "text" => "*Who should anchor this track tomorrow?*",
                   "type" => "mrkdwn"
                 },
                 "type" => "section"
               },
               %{
                 "elements" => [
                   %{
                     "text" => %{"text" => "Marc", "type" => "plain_text"},
                     "type" => "button",
                     "value" => "Marc"
                   },
                   %{
                     "text" => %{"text" => "Milo", "type" => "plain_text"},
                     "type" => "button",
                     "value" => "Milo"
                   },
                   %{
                     "text" => %{"emoji" => true, "text" => "🤝 Both", "type" => "plain_text"},
                     "type" => "button",
                     "value" => "both"
                   },
                   %{
                     "text" => %{
                       "emoji" => true,
                       "text" => "🎲 Feeling Lucky!",
                       "type" => "plain_text"
                     },
                     "type" => "button",
                     "value" => "random"
                   }
                 ],
                 "type" => "actions"
               }
             ]
    end

    test "does not send messages to teammates without slack ids", %{team: team} do
      {:ok, _} = Pears.add_pear(team.name, "Marc")
      {:ok, _} = Pears.add_track(team.name, "Feature 1")
      {:ok, _} = Pears.add_pear_to_track(team.name, "Marc", "Feature 1")

      {:ok, _} = Slack.send_end_of_session_questions(team.name, __MODULE__)

      refute_receive {:open_chat, _, _}
      refute_receive {:send_message, _, _, _}
    end
  end

  defp four_pears_two_tracks(%{team: team}) do
    Pears.add_pear(team.name, "Pear One")
    Pears.add_pear(team.name, "Pear Two")
    Pears.add_track(team.name, "Track One")
    Pears.add_pear_to_track(team.name, "Pear One", "Track One")
    Pears.add_pear_to_track(team.name, "Pear Two", "Track One")

    Pears.add_pear(team.name, "Pear Three")
    Pears.add_pear(team.name, "Pear Four")
    Pears.add_track(team.name, "Track Two")
    Pears.add_pear_to_track(team.name, "Pear Three", "Track Two")
    Pears.add_pear_to_track(team.name, "Pear Four", "Track Two")

    {:ok, team: team}
  end

  defp team(_) do
    {:ok, team} = Pears.add_team(Ecto.UUID.generate())
    {:ok, team: team}
  end
end
