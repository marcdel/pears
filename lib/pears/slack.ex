defmodule Pears.Slack do
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamSession
  alias Pears.Core.Team
  alias Pears.O11y
  alias Pears.Persistence
  alias Pears.Slack.Channel
  alias Pears.Slack.Details
  alias Pears.SlackClient

  @decorate trace("slack.link_url")
  def link_url do
    state = "onboard"
    client_id = "169408119024.1514845190500"
    scope = Enum.join(["channels:read", "chat:write.public", "chat:write"], ",")

    "https://slack.com/oauth/v2/authorize?redirect_uri=#{redirect_uri()}&state=#{state}&client_id=#{
      client_id
    }&scope=#{scope}&user_scope="
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

  @decorate trace("slack.get_details", include: [:team_name])
  def get_details(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, channels} <- fetch_channels(team.slack_token, slack_client),
         {:ok, users} <- fetch_users(team.slack_token, slack_client) do
      {:ok, Details.new(team, channels, users)}
    end
  end

  @decorate trace("slack.send_daily_pears_summary", include: [:team_name])
  def send_daily_pears_summary(team_name, slack_client \\ SlackClient) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         true <- FeatureFlags.enabled?(:send_daily_pears_summary, for: team),
         {:ok, message} <- build_daily_pears_summary(team),
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

  @decorate trace("slack.save_team_channel", include: [:team_name, :channel_name])
  def save_team_channel(team_name, channel_name) do
    with {:ok, team} <- TeamSession.find_or_start_session(team_name),
         {:ok, _} <- Persistence.set_slack_channel(team_name, channel_name),
         updated_team <- Team.set_slack_channel(team, channel_name),
         {:ok, updated_team} <- TeamSession.update_team(team_name, updated_team) do
      {:ok, updated_team}
    end
  end

  defp do_send_message_to_team(%{slack_token: nil}, _message, _slack_client) do
    {:error, :slack_token_not_set}
  end

  defp do_send_message_to_team(%{slack_channel: nil}, _message, _slack_client) do
    {:error, :slack_channel_not_set}
  end

  defp do_send_message_to_team(team, message, slack_client) do
    case slack_client.send_message(team.slack_channel, message, team.slack_token) do
      %{"ok" => true} = response ->
        O11y.set_attribute(:response, response)
        {:ok, message}

      error ->
        O11y.set_attribute(:error, error)
        {:error, error}
    end
  end

  defp build_daily_pears_summary(team) do
    summary_lines =
      team.tracks
      |> Map.values()
      |> Enum.map(&build_daily_pears_summary_line/1)
      |> Enum.join("\n")
      |> String.trim_trailing()

    summary = """
    Today's 🍐s are:
    #{summary_lines}
    """

    {:ok, summary}
  end

  defp build_daily_pears_summary_line(track) do
    match_text =
      track.pears
      |> Map.values()
      |> Enum.map_join(" & ", &Map.get(&1, :name))

    "\t- #{match_text} on #{track.name}"
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
          |> Enum.map(&Channel.from_json/1)

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
