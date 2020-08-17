defmodule Pears.Boundary.Instrumentation do
  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  alias Pears.Persistence

  def count_teams do
    count = Persistence.count_teams()
    :telemetry.execute([:pears, :teams], %{count: count})
  end

  @spec trace([atom()], keyword(), (:opentelemetry.span_ctx() -> any())) :: any()
  def trace(event_name, start_attrs, callback) do
    # Convert [:namespace, :event, :name] to "namespace.event.name" for opentelemetry
    span_name = Enum.join(event_name, ".")

    # Convert keyword list to map for :telemetry
    start_metadata = Enum.into(start_attrs, %{})

    OpenTelemetry.Tracer.with_span span_name do
      OpenTelemetry.Span.set_attributes(start_attrs)

      span_ctx = OpenTelemetry.Tracer.current_span_ctx()

      result =
        :telemetry.span(event_name, start_metadata, fn ->
          result = callback.(span_ctx)
          {result, Map.merge(start_metadata, %{result: inspect(result)})}
        end)

      OpenTelemetry.Span.set_attributes(result: inspect(result))

      result
    end
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
