defmodule Pears.Boundary.Instrumentation do
  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  alias Pears.Persistence

  def count_teams do
    count = Persistence.count_teams()
    :telemetry.execute([:pears, :teams], %{count: count})
  end

  def lookup_team_by_name(team_name, callback) do
    OpenTelemetry.Tracer.with_span "lookup_team_by_name" do
      OpenTelemetry.Span.set_attributes(team_name: team_name)

      call(callback)
    end
  end

  def add_pear_to_track(team_name, pear_name, track_name, callback) do
    OpenTelemetry.Tracer.with_span "add_pear_to_track" do
      OpenTelemetry.Span.set_attributes([
        {"team_name", team_name},
        {"pear_name", pear_name},
        {"track_name", track_name}
      ])

      call(callback)
    end
  end

  defp call(callback) do
    span_ctx = OpenTelemetry.Tracer.current_span_ctx()

    result = callback.(span_ctx)

    OpenTelemetry.Span.set_attributes([{"result", inspect(result)}])

    result
  end
end
