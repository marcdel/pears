defmodule Pears.O11y do
  require OpenTelemetry.Span, as: Span
  require OpenTelemetry.Tracer, as: Tracer

  @spec set_attribute(OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()) :: boolean()
  def set_attribute(key, value) do
    ctx = Tracer.current_span_ctx()
    Span.set_attribute(ctx, key, value)
  end

  @spec set_attributes([OpenTelemetry.attribute()]) :: boolean()
  def set_attributes(attrs) do
    ctx = Tracer.current_span_ctx()
    Span.set_attributes(ctx, attrs)
  end
end
