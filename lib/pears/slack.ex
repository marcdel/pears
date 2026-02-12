defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.Core.Team
  alias Pears.Persistence
  alias Pears.Slack.Channel
  alias Pears.Slack.Details
  alias Pears.Slack.Messages.DailyPairsMessage
  alias Pears.Slack.Messages.EndOfSessionQuestion
  alias Pears.Slack.Messages
  alias Pears.Slack.User

  def slack_client do
    Application.get_env(:pears, :slack_client, Pears.SlackClient)
  end

  @decorate trace("slack.link_url")
  def link_url do
    state = "onboard"
    client_id = "169408119024.1514845190500"

    scope =
      Enum.join(
        ["channels:read", "users:read", "chat:write.public", "chat:write", "im:write"],
        ","
      )

    user_scope = Enum.join([], ",")

    "https://slack.com/oauth/v2/authorize?redirect_uri=#{redirect_uri()}&state=#{state}&client_id=#{client_id}&scope=#{scope}&user_scope=#{user_scope}"
  end

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code) do
    with {:ok, token} <- fetch_tokens(slack_code),
         {:ok, _} <- Persistence.set_slack_token(team_name, token),
         {:ok, team} <- TeamSession.find_or_start_session(team_name),
         updated_team <- Team.set_slack_token(team, token),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  @decorate trace("slack.get_details", include: [:team_name, :_error])
  def get_details(team_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, pears} <- get_pears(team),
         {:ok, channels} <- load_or_fetch_channels(team_name, team.slack_token),
         {:ok, users} <- load_or_fetch_users(team_name, team.slack_token) do
      {:ok, Details.new(team, channels, users, pears)}
    else
      error ->
        O11y.set_error(error)
        {:error, Details.empty()}
    end
  end

  @decorate trace("slack.send_end_of_session_questions", include: [:team_name])
  def send_end_of_session_questions(team_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         true <- FeatureFlags.enabled?(:send_end_of_session_questions, for: team),
         {:ok, messages} <- do_send_end_of_session_questions(team) do
      {:ok, messages}
    else
      error -> error
    end
  end

  @decorate trace("slack.send_daily_pears_summary", include: [:team_name])
  def send_daily_pears_summary(team_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         true <- FeatureFlags.enabled?(:send_daily_pears_summary, for: team),
         {:ok, message} <- DailyPairsMessage.new(team),
         :ok <- do_send_message_to_team(team, message) do
      :ok
    else
      error -> error
    end
  end

  @decorate trace("slack.send_message_to_team", include: [:team_name, :message])
  def send_message_to_team(team_name, message) do
    case TeamSession.find_or_start_session(team_name) do
      {:ok, team} -> do_send_message_to_team(team, message)
      error -> error
    end
  end

  @decorate trace("slack.save_team_channel", include: [:team_name, :team_channel])
  def save_team_channel(details, team_name, team_channel) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, _} <- Persistence.set_slack_channel(team_name, team_channel),
         updated_team <- Team.set_slack_channel(team, team_channel),
         {:ok, _} <- TeamSession.update_team(team_name, updated_team),
         updated_details <- %{details | team_channel: team_channel} do
      {:ok, updated_details}
    else
      _ -> {:ok, details}
    end
  end

  @decorate trace("slack.save_slack_names", include: [:team_name, :params])
  def save_slack_names(details, team_name, params) do
    with updated_pears <- do_save_slack_names(team_name, details.users, details.pears, params),
         updated_details <- update_pears_on_details(details, updated_pears) do
      {:ok, updated_details}
    end
  end

  @decorate trace("slack.send_hand_off_reminder")
  def send_hand_off_reminder(team, pears) do
    message = Messages.HandOffReminder.new()
    send_message_to_pears(team, pears, message)
  end

  defp do_save_slack_names(team_name, users, pears, params) do
    Enum.map(params, fn
      {pear_name, ""} ->
        {:ok, Enum.find(pears, fn pear -> pear.name == pear_name end)}

      {pear_name, slack_id} ->
        with {:ok, team} <- TeamSession.find_or_start_session(team_name),
             %User{} = user <- Enum.find(users, fn user -> user.id == slack_id end),
             {:ok, pear_record} <-
               Persistence.add_pear_slack_details(team.name, pear_name, %{
                 slack_id: user.id,
                 slack_name: user.name,
                 timezone_offset: user.tz_offset
               }),
             updated_team <-
               Team.update_pear(team, pear_name,
                 slack_name: user.name,
                 slack_id: user.id,
                 timezone_offset: user.tz_offset
               ),
             {:ok, _updated_team} <- TeamSession.update_team(team.name, updated_team) do
          {:ok, pear_record}
        end
    end)
    |> Enum.reject(&(&1 == nil))
    |> Enum.group_by(fn {success, _} -> success end, fn {_, result} -> result end)
    |> Map.get(:ok, [])
  end

  defp update_pears_on_details(details, updated_pears) do
    updated_detail_pears =
      updated_pears
      |> Enum.reduce(Enum.group_by(details.pears, & &1.id), fn updated_pear, pears_map ->
        Map.put(pears_map, updated_pear.id, updated_pear)
      end)
      |> Map.values()
      |> List.flatten()

    %{details | pears: updated_detail_pears}
  end

  defp do_send_message_to_team(team, message) do
    channel_id = if team.slack_channel != nil, do: team.slack_channel.id, else: nil
    do_send_message(team, channel_id, message)
  end

  defp do_send_end_of_session_questions(team) do
    results =
      team
      |> Team.rotatable_tracks()
      |> Enum.map(&do_send_end_of_session_question(team, &1))

    {:ok, results}
  end

  defp do_send_end_of_session_question(team, track) do
    message = EndOfSessionQuestion.new(track)
    send_message_to_pears(team, Map.values(track.pears), message)
  end

  defp send_message_to_pears(team, pears, message) do
    case find_or_create_group_chat(team, pears) do
      {:ok, channel_id} -> do_send_message(team, channel_id, message)
      _ -> {:error, :error_creating_group_chat}
    end
  end

  @decorate trace("slack.find_or_create_group_chat", include: [:pears, :user_ids])
  defp find_or_create_group_chat(%{slack_token: token}, pears) do
    user_ids = Enum.map(pears, &Map.get(&1, :slack_id))

    case slack_client().find_or_create_group_chat(user_ids, token) do
      %{"ok" => true} = response ->
        O11y.set_attribute(:response, response)
        {:ok, get_in(response, ["channel", "id"])}

      error ->
        O11y.set_error(error)
        {:error, error}
    end
  end

  defp do_send_message(%{slack_token: nil}, _channel, _message) do
    O11y.set_error(:slack_token_not_set)
    {:error, :slack_token_not_set}
  end

  defp do_send_message(_team, nil, _message) do
    O11y.set_error(:slack_channel_not_set)
    {:error, :slack_channel_not_set}
  end

  defp do_send_message(%{slack_token: token}, channel, message) do
    case slack_client().send_message(channel, message, token) do
      %{"ok" => true} = response ->
        O11y.set_attribute(:response, response)
        {:ok, message}

      error ->
        O11y.set_error(error)
        {:error, error}
    end
  end

  defp fetch_tokens(slack_code) do
    case slack_client().retrieve_access_tokens(slack_code, redirect_uri()) do
      %{"ok" => true} = response ->
        {:ok, Map.get(response, "access_token")}

      error ->
        O11y.set_error(error)
        {:error, :invalid_code}
    end
  end

  @decorate trace("slack.get_pears", include: [:team_name])
  defp get_pears(%{name: team_name}) do
    with {:ok, team} <- Persistence.get_team_by_name(team_name) do
      {:ok, Enum.sort_by(team.pears, &Map.get(&1, :name))}
    end
  end

  defp load_or_fetch_channels(team_name, token) do
    with {:ok, []} <- TeamSession.slack_channels(team_name),
         {:ok, channels} <- fetch_channels(token) do
      TeamSession.add_slack_channels(team_name, channels)
    end
  end

  defp fetch_channels(nil), do: {:error, :no_token}

  defp fetch_channels(token) do
    case do_fetch_channels(token, "") do
      {:error, :invalid_token} -> {:error, :invalid_token}
      channels -> {:ok, Enum.sort_by(channels, &Map.get(&1, :name))}
    end
  end

  @decorate trace("slack.fetch_channels", include: [:cursor, :next_cursor])
  defp do_fetch_channels(token, cursor) do
    case slack_client().channels(token, cursor) do
      %{"ok" => true} = response ->
        channels =
          response
          |> Map.get("channels", [])
          |> Enum.map(&Channel.from_json/1)

        O11y.set_attribute(:channel_count, Enum.count(channels))

        next_cursor = get_in(response, ["response_metadata", "next_cursor"]) || ""

        case next_cursor do
          "" -> channels
          cursor -> channels ++ do_fetch_channels(token, cursor)
        end

      error ->
        O11y.set_error(error)
        {:error, :invalid_token}
    end
  end

  defp load_or_fetch_users(team_name, token) do
    with {:ok, []} <- TeamSession.slack_users(team_name),
         {:ok, users} <- fetch_users(token) do
      TeamSession.add_slack_users(team_name, users)
    end
  end

  defp fetch_users(nil), do: {:error, :no_token}

  defp fetch_users(token) do
    case do_fetch_users(token, "") do
      {:error, :invalid_token} -> {:error, :invalid_token}
      users -> {:ok, Enum.sort_by(users, &Map.get(&1, :name))}
    end
  end

  @decorate trace("slack.fetch_users", include: [:cursor, :next_cursor])
  defp do_fetch_users(token, cursor) do
    case slack_client().users(token, cursor) do
      %{"ok" => true} = response ->
        users =
          response
          |> Map.get("members", [])
          |> Enum.map(&User.from_json/1)

        O11y.set_attribute(:user_count, Enum.count(users))

        next_cursor = get_in(response, ["response_metadata", "next_cursor"]) || ""

        case next_cursor do
          "" -> users
          cursor -> users ++ do_fetch_users(token, cursor)
        end

      error ->
        O11y.set_error(error)
        {:error, :invalid_token}
    end
  end

  defp redirect_uri, do: Application.get_env(:pears, :slack_oauth_redirect_uri)
end
