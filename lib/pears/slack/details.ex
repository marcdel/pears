defmodule Pears.Slack.Details do
  defstruct [:token, :channels, :users, :team_channel, has_token: false]

  def new(team, channels, users) do
    %__MODULE__{
      token: team.slack_token,
      has_token: team.slack_token != nil,
      channels: channels,
      users: users,
      team_channel: team.slack_channel
    }
  end
end
