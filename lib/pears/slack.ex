defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.Core.Team
  alias Pears.O11y
  alias Pears.Persistence
  alias Pears.Slack.Channel
  alias Pears.Slack.Details
  alias Pears.Slack.Messages.DailyPairsMessage
  alias Pears.Slack.Messages.EndOfSessionQuestion
  alias Pears.Slack.User
  alias Pears.SlackClient

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

    "https://slack.com/oauth/v2/authorize?redirect_uri=#{redirect_uri()}&state=#{state}&client_id=#{
      client_id
    }&scope=#{scope}&user_scope=#{user_scope}"
  end

  @decorate trace("slack.onboard_team", include: [:team_name])
  def onboard_team(team_name, slack_code, slack_client \\ SlackClient) do
    with {:ok, token} <- fetch_tokens(slack_code, slack_client),
         {:ok, _} <- Persistence.set_slack_token(team_name, token),
         {:ok, team} <- TeamSession.find_or_start_session(team_name),
         updated_team <- Team.set_slack_token(team, token),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  @decorate trace("slack.get_details", include: [:team_name, :_error])
  def get_details(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, pears} <- get_pears(team),
         {:ok, channels} <- load_or_fetch_channels(team_name, team.slack_token, slack_client),
         {:ok, users} <- load_or_fetch_users(team_name, team.slack_token, slack_client) do
      {:ok, Details.new(team, channels, users, pears)}
    else
      _error -> {:error, Details.empty()}
    end
  end

  @decorate trace("slack.send_end_of_session_questions", include: [:team_name])
  def send_end_of_session_questions(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         true <- FeatureFlags.enabled?(:send_end_of_session_questions, for: team),
         {:ok, messages} <- do_send_end_of_session_questions(team, slack_client) do
      {:ok, messages}
    else
      error -> error
    end
  end

  @decorate trace("slack.send_daily_pears_summary", include: [:team_name])
  def send_daily_pears_summary(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         true <- FeatureFlags.enabled?(:send_daily_pears_summary, for: team),
         {:ok, message} <- DailyPairsMessage.new(team),
         :ok <- do_send_message_to_team(team, message, slack_client) do
      :ok
    else
      error -> error
    end
  end

  @decorate trace("slack.send_message_to_team", include: [:team_name, :message])
  def send_message_to_team(team_name, message, slack_client \\ SlackClient) do
    case TeamSession.find_or_start_session(team_name) do
      {:ok, team} -> do_send_message_to_team(team, message, slack_client)
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

  defp do_save_slack_names(team_name, users, pears, params) do
    Enum.map(params, fn
      {pear_name, ""} ->
        {:ok, Enum.find(pears, fn pear -> pear.name == pear_name end)}

      {pear_name, slack_id} ->
        with {:ok, team} <- TeamSession.find_or_start_session(team_name),
             user <- Enum.find(users, fn user -> user.id == slack_id end),
             {:ok, pear_record} <-
               Persistence.add_pear_slack_details(team.name, pear_name, %{
                 slack_id: user.id,
                 slack_name: user.name
               }),
             updated_team <-
               Team.update_pear(team, pear_name,
                 slack_name: user.name,
                 slack_id: user.id
               ),
             {:ok, _updated_team} <- TeamSession.update_team(team.name, updated_team) do
          {:ok, pear_record}
        end
    end)
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

  defp do_send_message_to_team(team, message, slack_client) do
    channel_id = if team.slack_channel != nil, do: team.slack_channel.id, else: nil
    do_send_message(team, channel_id, message, slack_client)
  end

  defp do_send_end_of_session_questions(team, slack_client) do
    results =
      team
      |> Team.rotatable_tracks()
      |> Enum.map(&do_send_end_of_session_question(team, &1, slack_client))

    {:ok, results}
  end

  defp do_send_end_of_session_question(team, track, slack_client) do
    message = EndOfSessionQuestion.new(track)

    case find_or_create_group_chat(team, track, slack_client) do
      {:ok, channel_id} -> do_send_message(team, channel_id, message, slack_client)
      _ -> {:error, :error_creating_group_chat}
    end
  end

  @decorate trace("slack.find_or_create_group_chat", include: [[:track, :pears], :user_ids])
  defp find_or_create_group_chat(%{slack_token: token}, track, slack_client) do
    user_ids =
      track.pears
      |> Map.values()
      |> Enum.map(&Map.get(&1, :slack_id))

    case slack_client.find_or_create_group_chat(user_ids, token) do
      %{"ok" => true} = response ->
        O11y.set_attribute(:response, response)
        {:ok, get_in(response, ["channel", "id"])}

      error ->
        O11y.set_attribute(:error, error)
        {:error, error}
    end
  end

  defp do_send_message(%{slack_token: nil}, _channel, _message, _slack_client) do
    {:error, :slack_token_not_set}
  end

  defp do_send_message(_team, nil, _message, _slack_client) do
    {:error, :slack_channel_not_set}
  end

  defp do_send_message(%{slack_token: token}, channel, message, slack_client) do
    case slack_client.send_message(channel, message, token) do
      %{"ok" => true} = response ->
        O11y.set_attribute(:response, response)
        {:ok, message}

      error ->
        O11y.set_attribute(:error, error)
        {:error, error}
    end
  end

  defp fetch_tokens(slack_code, slack_client) do
    case slack_client.retrieve_access_tokens(slack_code, redirect_uri()) do
      %{"ok" => true} = response ->
        {:ok, Map.get(response, "access_token")}

      error ->
        O11y.set_attribute(:error, error)
        {:error, :invalid_code}
    end
  end

  @decorate trace("slack.get_pears", include: [:team_name])
  defp get_pears(%{name: team_name}) do
    with {:ok, team} <- Persistence.get_team_by_name(team_name) do
      {:ok, Enum.sort_by(team.pears, &Map.get(&1, :name))}
    end
  end

  defp load_or_fetch_channels(team_name, token, slack_client) do
    with {:ok, []} <- TeamSession.slack_channels(team_name),
         {:ok, channels} <- fetch_channels(token, slack_client) do
      TeamSession.add_slack_channels(team_name, channels)
    end
  end

  defp fetch_channels(nil, _slack_client), do: {:error, :no_token}

  defp fetch_channels(token, slack_client) do
    case do_fetch_channels(token, "", slack_client) do
      {:error, :invalid_token} -> {:error, :invalid_token}
      channels -> {:ok, Enum.sort_by(channels, &Map.get(&1, :name))}
    end
  end

  @decorate trace("slack.fetch_channels", include: [:cursor, :next_cursor])
  defp do_fetch_channels(token, cursor, slack_client) do
    case slack_client.channels(token, cursor) do
      %{"ok" => true} = response ->
        channels =
          response
          |> Map.get("channels")
          |> Enum.map(&Channel.from_json/1)

        O11y.set_attribute(:channel_count, Enum.count(channels))

        case response do
          %{"response_metadata" => %{"next_cursor" => ""}} ->
            channels

          %{"response_metadata" => %{"next_cursor" => next_cursor}} ->
            channels ++ do_fetch_channels(token, next_cursor, slack_client)
        end

      error ->
        O11y.set_attribute(:error, error)
        {:error, :invalid_token}
    end
  end

  defp load_or_fetch_users(team_name, token, slack_client) do
    with {:ok, []} <- TeamSession.slack_users(team_name),
         {:ok, users} <- fetch_users(token, slack_client) do
      TeamSession.add_slack_users(team_name, users)
    end
  end

  defp fetch_users(nil, _slack_client), do: {:error, :no_token}

  defp fetch_users(token, slack_client) do
    case do_fetch_users(token, "", slack_client) do
      {:error, :invalid_token} -> {:error, :invalid_token}
      users -> {:ok, Enum.sort_by(users, &Map.get(&1, :name))}
    end
  end

  @decorate trace("slack.fetch_users", include: [:cursor, :next_cursor])
  defp do_fetch_users(token, cursor, slack_client) do
    case slack_client.users(token, cursor) do
      %{"ok" => true} = response ->
        users =
          response
          |> Map.get("members")
          |> Enum.map(&User.from_json/1)

        O11y.set_attribute(:user_count, Enum.count(users))

        case response do
          %{"response_metadata" => %{"next_cursor" => ""}} ->
            users

          %{"response_metadata" => %{"next_cursor" => next_cursor}} ->
            users ++ do_fetch_users(token, next_cursor, slack_client)
        end

      error ->
        O11y.set_attribute(:error, error)
        {:error, :invalid_token}
    end
  end

  defp redirect_uri, do: Application.get_env(:pears, :slack_oauth_redirect_uri)
end
