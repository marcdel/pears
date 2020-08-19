defmodule Pears.O11y.Tracer do
  @spec trace([atom()], map(), (() -> any())) :: any()
  def trace(event_name, start_metadata, callback) do
    :telemetry.span(event_name, start_metadata, fn ->
      case callback.() do
        %{result: result, metadata: metadata} ->
          {result, Map.merge(start_metadata, metadata)}

        result ->
          {result, Map.merge(start_metadata, %{result: result})}
      end
    end)
  end

  alias Pears.Core.Team

  @doc """
  Trace events that take a team and return a team and
  automatically add before and after team metadata
  """
  def trace_team_event(opts) do
    event_name = Keyword.fetch!(opts, :event_name)
    team = Keyword.fetch!(opts, :team)
    metadata = Keyword.get(opts, :metadata, %{})
    callback = Keyword.fetch!(opts, :callback)

    start_metadata = Map.merge(metadata, %{team_before: Team.metadata(team)})

    wrapped_callback = fn ->
      updated_team = callback.()

      updated_metadata = Map.merge(metadata, %{team_after: Team.metadata(updated_team)})

      %{result: updated_team, metadata: updated_metadata}
    end

    trace(event_name, start_metadata, wrapped_callback)
  end
end
