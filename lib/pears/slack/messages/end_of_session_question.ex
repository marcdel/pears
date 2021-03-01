defmodule Pears.Slack.Messages.EndOfSessionQuestion do
  def new(track) do
    [
      %{
        "type" => "section",
        "text" => %{
          "type" => "mrkdwn",
          "text" =>
            "Hey, friends! 👋\n\nTo make tomorrow's standup even smoother, I wanted to check whether you've decided who would like to continue working on your current track (#{
              track.name
            }) and who will rotate to another track."
        }
      },
      %{
        "type" => "divider"
      },
      %{
        "type" => "section",
        "text" => %{
          "type" => "mrkdwn",
          "text" => "*Who should anchor this track tomorrow?*"
        }
      },
      %{
        "type" => "actions",
        "elements" => pear_buttons(track) ++ static_buttons()
      }
    ]
  end

  defp pear_buttons(track) do
    track.pears
    |> Map.values()
    |> Enum.map(fn %{name: name} ->
      %{
        "type" => "button",
        "text" => %{
          "type" => "plain_text",
          "text" => name
        },
        "value" => "anchor-#{name}"
      }
    end)
  end

  defp static_buttons do
    [
      %{
        "type" => "button",
        "text" => %{
          "type" => "plain_text",
          "text" => "🤝 Both",
          "emoji" => true
        },
        "value" => "anchor-both"
      },
      %{
        "type" => "button",
        "text" => %{
          "type" => "plain_text",
          "text" => "🎲 Feeling Lucky!",
          "emoji" => true
        },
        "value" => "anchor-random"
      }
    ]
  end
end
