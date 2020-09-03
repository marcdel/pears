defmodule Pears.O11y.Decorator do
  use Decorator.Define, trace_decorator: 1, trace_decorator: 2

  def trace_decorator(event_name, attr_keys \\ [], body, context) do
    validate_args(event_name, attr_keys)
    event_name = Enum.join(event_name, ".")

    quote location: :keep do
      require OpenTelemetry.Span
      require OpenTelemetry.Tracer

      OpenTelemetry.Tracer.with_span unquote(event_name) do
        parent_ctx = OpenTelemetry.Tracer.current_span_ctx()

        result = unquote(body)

        maybe_add_team_name = fn attrs ->
          if Keyword.has_key?(attrs, :team) do
            Keyword.put_new(attrs, :team_name, attrs[:team].name)
          else
            attrs
          end
        end

        pretty_print = fn attrs ->
          Enum.map(attrs, fn {key, value} -> {key, Pears.O11y.pretty_inspect(value)} end)
        end

        reportable_attrs =
          Kernel.binding()
          |> Keyword.take(unquote(attr_keys))
          |> Keyword.put_new(:result, result)
          |> maybe_add_team_name.()
          |> pretty_print.()
          |> Enum.into([])

        OpenTelemetry.Span.set_attributes(reportable_attrs)

        result
      end
    end
  rescue
    e in ArgumentError ->
      target = "#{inspect(context.module)}.#{context.name}/#{context.arity} @decorate telemetry"
      reraise %ArgumentError{message: "#{target} #{e.message}"}, __STACKTRACE__
  end

  defp validate_args(event_name, attr_keys) do
    if not (is_list(event_name) and atoms_only?(event_name) and not Enum.empty?(event_name)),
      do: raise(ArgumentError, "event_name must be a non-empty list of atoms")

    if Enum.empty?(event_name), do: raise(ArgumentError, "event_name is empty")

    if not (is_list(attr_keys) and atoms_only?(attr_keys)),
      do: raise(ArgumentError, "include option must be a list of atoms")
  end

  defp atoms_only?(list), do: Enum.all?(list, &is_atom/1)
end
