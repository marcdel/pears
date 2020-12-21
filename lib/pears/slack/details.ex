defmodule Pears.Slack.Details do
  defstruct [
    :token,
    :channels,
    :team_channel,
    pears: [],
    users: [],
    has_token: false,
    all_pears_updated: false
  ]

  def new(team, channels, users, pears) do
    %__MODULE__{
      token: team.slack_token,
      has_token: team.slack_token != nil,
      pears: pears,
      channels: channels,
      users: users,
      team_channel: team.slack_channel,
      all_pears_updated: Enum.all?(pears, fn pear -> pear.slack_id != nil end)
    }
  end
end
