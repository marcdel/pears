defmodule Pears.O11y.Tracer do
  @spec trace([atom()], map(), (() -> any())) :: any()
  def trace(event_name, start_metadata, callback) do
    :telemetry.span(event_name, start_metadata, fn ->
      case callback.() do
        %{result: result, metadata: metadata} ->
          {result, Map.merge(start_metadata, metadata)}

        result ->
          {result, Map.merge(start_metadata, %{result: inspect(result)})}
      end
    end)
  end
end
