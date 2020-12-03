defmodule Pears.Slack.Details do
  defstruct [:token, :channels, :team_channel, has_token: false]

  def new(team, token, channels) do
    %__MODULE__{
      token: token,
      has_token: token != nil,
      channels: channels,
      team_channel: team.slack_channel
    }
  end
end
