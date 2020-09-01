defmodule Pears.O11y.Pears do
  alias Pears.O11y

  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  def lookup_team_by_name(team_name, parent_ctx, callback) do
    O11y.trace(%{
      event_name: "pears.lookup_team_by_name",
      team_name: team_name,
      parent_ctx: parent_ctx,
      callback: callback
    })
  end

  def recommend_pears(team_name, parent_ctx, callback) do
    O11y.trace(%{
      event_name: "pears.recommend_pears",
      team_name: team_name,
      parent_ctx: parent_ctx,
      callback: callback
    })
  end

  def maybe_add_empty_tracks(team, parent_ctx, callback) do
    O11y.trace(%{
      event_name: "pears.maybe_add_empty_tracks",
      team: team,
      parent_ctx: parent_ctx,
      callback: callback
    })
  end

  def add_pear_to_track(team_name, pear_name, track_name, parent_ctx, callback) do
    O11y.trace(%{
      event_name: "pears.add_pear_to_track",
      attrs: %{
        pear_name: pear_name,
        track_name: track_name
      },
      team_name: team_name,
      parent_ctx: parent_ctx,
      callback: callback
    })
  end
end
