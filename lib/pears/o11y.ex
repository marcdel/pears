defmodule O11y do
  alias OpenTelemetryDecorator.Attributes

  @spec set_attribute(OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()) :: boolean()
  def set_attribute(key, value) do
    Attributes.set(key, value)
  end

  @spec set_attributes([OpenTelemetry.attribute()]) :: boolean()
  def set_attributes(attrs) do
    Attributes.set(attrs)
  end
end
