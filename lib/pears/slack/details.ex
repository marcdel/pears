defmodule Pears.Slack.Details do
  alias Pears.Slack.Channel

  defstruct [
    :token,
    team_channel: Channel.empty(),
    channels: [],
    pears: [],
    users: [],
    has_token: false,
    has_team_channel: false,
    all_pears_updated: false,
    no_channels: true
  ]

  def empty, do: %__MODULE__{}

  def new(team, channels, users, pears) do
    %__MODULE__{
      token: team.slack_token,
      has_token: team.slack_token != nil,
      pears: pears,
      channels: channels,
      users: users,
      team_channel: team.slack_channel,
      no_channels: Enum.empty?(channels),
      all_pears_updated: Enum.all?(pears, fn pear -> pear.slack_id != nil end)
    }
  end
end
