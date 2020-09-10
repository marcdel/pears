defmodule Pears.O11y do
  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  def pretty_inspect(thing)
      when is_map(thing) or is_struct(thing) or is_list(thing) do
    Kernel.inspect(
      thing,
      pretty: true,
      structs: false,
      limit: :infinity,
      width: :infinity
    )
  end

  def pretty_inspect(thing), do: thing

  def inspect(thing)
      when is_map(thing) or is_struct(thing) or is_list(thing) do
    Kernel.inspect(thing)
  end

  def inspect(thing), do: thing
end
