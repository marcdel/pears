defmodule Pears.O11y do
  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  @spec set_attribute(OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()) :: boolean()
  def set_attribute(key, value), do: OpenTelemetry.Span.set_attribute(key, value)

  @spec set_attributes([OpenTelemetry.attribute()]) :: boolean()
  def set_attributes(attrs), do: OpenTelemetry.Span.set_attributes(attrs)
end
