defmodule Pears.SlackTest do
  use Pears.DataCase, async: true

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  alias Pears.MockSlackClient
  alias Pears.Persistence
  alias Pears.Slack
  alias Pears.Slack.Details
  alias Pears.Slack.Messages.EndOfSessionQuestion
  alias Pears.SlackFixtures

  setup [:team]

  @valid_code SlackFixtures.valid_code()
  @valid_token SlackFixtures.valid_token()

  @valid_open_chat_response SlackFixtures.open_chat_response(id: "GROUPCHATID")

  setup do
    stub_with(MockSlackClient, FakeSlackClient)
    :ok
  end

  describe "onboard_team" do
    test "exchanges a code for an access token and saves it", %{team: team} do
      valid_token = "xoxb-XXXXXXXX-XXXXXXXX-XXXXX"

      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.valid_token_response(%{access_token: valid_token})
      end)

      {:ok, team} = Slack.onboard_team(team.name, "valid_code")
      assert team.slack_token == valid_token

      {:ok, team_record} = Persistence.get_team_by_name(team.name)
      assert team_record.slack_token == valid_token
    end

    test "handles invalid responses", %{team: team} do
      expect(MockSlackClient, :retrieve_access_tokens, fn _code, _url ->
        SlackFixtures.invalid_token_response()
      end)

      {:error, _} = Slack.onboard_team(team.name, "invalid_code")
    end
  end

  describe "get_details" do
    setup %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)

      :ok
    end

    test "returns a list of all channels in the slack organization", %{team: team} do
      MockSlackClient
      |> expect(:channels, fn _, "" -> SlackFixtures.conversations_response(page: 1) end)
      |> expect(:channels, fn _, _ -> SlackFixtures.conversations_response(page: 2) end)

      {:ok, details} = Slack.get_details(team.name)
      assert [%{name: "general"}, %{name: "random"}] = details.channels
    end

    test "returns a list of all users in the slack organization", %{team: team} do
      MockSlackClient
      |> expect(:users, fn _, "" -> SlackFixtures.list_users_response(1) end)
      |> expect(:users, fn _, _ -> SlackFixtures.list_users_response(2) end)

      {:ok, details} = Slack.get_details(team.name)

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

      {:ok, details} = Slack.get_details(team.name)

      assert [
               %{slack_id: nil, slack_name: nil, name: "marc"},
               %{slack_id: "XXXXXXXXXX", slack_name: "miloooooo", name: "milo"}
             ] = details.pears
    end

    test "handles invalid responses" do
      {:ok, _} = Pears.add_team("no token")
      assert {:error, details} = Slack.get_details("no token")
      assert details == Details.empty()
      {:ok, _} = Pears.remove_team("no token")
    end

    test "returns the team's slack_channel", %{team: team} do
      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "cool team"})

      {:ok, details} = Slack.get_details(team.name)

      assert details.team_channel == %{id: "UXXXXXXX", name: "cool team"}
    end
  end

  describe "save_team_channel" do
    test "sets the team slack_channel to the provided channel", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)
      {:ok, details} = Slack.get_details(team.name)

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
      MockSlackClient
      |> expect(:users, fn _, "" -> SlackFixtures.list_users_response(1) end)
      |> expect(:users, fn _, _ -> SlackFixtures.list_users_response(2) end)

      {:ok, _} = Slack.onboard_team(team.name, @valid_code)
      {:ok, _} = Pears.add_pear(team.name, "Marc")
      {:ok, _} = Pears.add_pear(team.name, "Milo")
      {:ok, _} = Pears.add_pear(team.name, "Jackie")
      {:ok, details} = Slack.get_details(team.name)

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
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)

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
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)

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
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)

      {:ok, _} =
        Slack.save_team_channel(Details.empty(), team.name, %{id: "UXXXXXXX", name: "random"})

      FeatureFlags.disable(:send_daily_pears_summary, for_actor: team)

      Slack.send_daily_pears_summary(team.name, __MODULE__)

      refute_receive {:send_message, _, _, _}
    end

    test "does not send a message if no channel is specified", %{team: team} do
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)
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
      {:ok, _} = Slack.onboard_team(team.name, @valid_code)
      :ok
    end

    test "sends a message to each set of pears", %{team: team} do
      MockSlackClient
      |> expect(:users, fn _, "" -> SlackFixtures.list_users_response(1) end)
      |> expect(:users, fn _, _ -> SlackFixtures.list_users_response(2) end)

      {:ok, _} = Pears.add_pear(team.name, "Marc")
      {:ok, _} = Pears.add_pear(team.name, "Milo")
      {:ok, _} = Pears.add_track(team.name, "Feature 1")
      {:ok, _} = Pears.add_pear_to_track(team.name, "Marc", "Feature 1")
      {:ok, team} = Pears.add_pear_to_track(team.name, "Milo", "Feature 1")
      {:ok, details} = Slack.get_details(team.name)
      track = Map.get(team.tracks, "Feature 1")

      params = %{"Marc" => "XXXXXXXXXX", "Milo" => "YYYYYYYYYY"}
      {:ok, _} = Slack.save_slack_names(details, team.name, params)

      {:ok, _} = Slack.send_end_of_session_questions(team.name, __MODULE__)

      assert_receive {:open_chat, ["XXXXXXXXXX", "YYYYYYYYYY"], token}
      assert token == @valid_token

      assert_receive {:send_message, "GROUPCHATID", blocks, token}
      assert token == @valid_token

      assert blocks == EndOfSessionQuestion.new(track)
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
