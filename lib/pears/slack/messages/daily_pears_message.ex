defmodule Pears.Slack.Messages.DailyPairsMessage do
  def new(team) do
    build_daily_pears_summary(team)
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
end
