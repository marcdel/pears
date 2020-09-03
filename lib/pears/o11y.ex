defmodule Pears.O11y do
  require OpenTelemetry.Span
  require OpenTelemetry.Tracer

  def pretty_inspect(thing)
      when is_map(thing) or is_struct(thing) or is_list(thing) do
    inspect(
      thing,
      pretty: true,
      structs: false,
      limit: :infinity,
      width: :infinity
    )
  end

  def pretty_inspect(thing), do: thing
end
