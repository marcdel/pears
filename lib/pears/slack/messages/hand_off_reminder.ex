defmodule Pears.Slack.Messages.HandOffReminder do
  def new do
    [
      %{
        "type" => "section",
        "text" => %{
          "type" => "mrkdwn",
          "text" =>
            "Hey, friends! 👋\n\nLooks like you're pairing across timezones!\nThis is your friendly reminder to update your pair with any context they might need to get started tomorrow."
        }
      },
      %{
        "type" => "divider"
      }
    ]
  end
end
