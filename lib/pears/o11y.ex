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

  def parent_ctx, do: OpenTelemetry.Tracer.current_span_ctx()

  @doc """
  Trace events that take a team or team name and returns
  a team and automatically adds before and after team metadata
  """
  def trace(%{team: team} = opts) do
    opts
    |> Map.update(:attrs, %{}, fn attrs ->
      attrs
      |> Map.put(:team_name, team.name)
      |> Map.put(:team, pretty_inspect(team))
    end)
    |> do_trace()
  end

  def trace(%{team_name: team_name} = opts) do
    opts
    |> Map.update(:attrs, %{}, &Map.put(&1, :team_name, team_name))
    |> do_trace()
  end

  defp do_trace(opts) do
    event_name = Map.fetch!(opts, :event_name)
    attrs = Map.get(opts, :attrs, %{})
    parent_ctx = Map.get(opts, :parent_ctx, nil)
    callback = Map.fetch!(opts, :callback)

    OpenTelemetry.Tracer.with_span event_name, %{parent: parent_ctx} do
      OpenTelemetry.Span.set_attributes(Enum.into(attrs, []))

      ctx = OpenTelemetry.Tracer.current_span_ctx()

      result = callback.(ctx)

      OpenTelemetry.Span.set_attributes(result: pretty_inspect(result))

      result
    end
  end
end
