defmodule Pears.Slack.Details do
  defstruct [:token, :channels, :team_channel, pears: [], users: [], has_token: false]

  def new(team, channels, users, pears) do
    %__MODULE__{
      token: team.slack_token,
      has_token: team.slack_token != nil,
      pears: pears,
      channels: channels,
      users: users,
      team_channel: team.slack_channel_name
    }
  end
end
