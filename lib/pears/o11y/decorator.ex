defmodule Pears.O11y.Decorator do
  use Decorator.Define, trace: 1, trace: 2

  def trace(event_name, attr_keys \\ [], body, context) do
    validate_args(event_name, attr_keys)

    event_name = Enum.join(event_name, ".")

    quote location: :keep do
      require OpenTelemetry.Span
      require OpenTelemetry.Tracer

      alias Pears.O11y.Decorator

      maybe_add_team_name = fn attrs ->
        if Keyword.has_key?(attrs, :team) do
          Keyword.put_new(attrs, :team_name, attrs[:team].name)
        else
          attrs
        end
      end

      parent_ctx = OpenTelemetry.Tracer.current_span_ctx()

      OpenTelemetry.Tracer.with_span unquote(event_name), %{parent: parent_ctx} do
        result = unquote(body)

        reportable_attrs =
          Kernel.binding()
          |> Decorator.take_attrs(unquote(attr_keys))
          |> maybe_add_team_name.()
          # |> Keyword.put_new(:result, result)
          |> Decorator.maybe_add_result(unquote(attr_keys), result)
          |> Decorator.remove_underscores()
          |> Decorator.stringify_list()
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

  def take_attrs(bound_values, attr_keys) do
    {keys, nested_keys} = Enum.split_with(attr_keys, &is_atom/1)

    attrs = Keyword.take(bound_values, keys)

    nested_attrs =
      Enum.map(nested_keys, fn key_list ->
        key = key_list |> Enum.join("_") |> String.to_atom()
        {obj_key, other_keys} = List.pop_at(key_list, 0)
        value = get_in(bound_values, [obj_key | Enum.map(other_keys, &Access.key(&1, nil))])
        {key, value}
      end)

    Keyword.merge(nested_attrs, attrs)
  end

  def maybe_add_result(attrs, attr_keys, result) do
    if Enum.member?(attr_keys, :result) do
      Keyword.put_new(attrs, :result, result)
    else
      attrs
    end
  end

  def remove_underscores(attrs) do
    Enum.map(attrs, fn {key, value} ->
      key =
        key
        |> Atom.to_string()
        |> String.trim_leading("_")
        |> String.to_existing_atom()

      {key, value}
    end)
  end

  def stringify_list(attrs) do
    Enum.map(attrs, fn {key, value} -> {key, Pears.O11y.inspect(value)} end)
  end

  def stringify(thing) when is_map(thing) or is_struct(thing) or is_list(thing) do
    inspect(thing)
  end

  def stringify(thing), do: thing

  def validate_args(event_name, attr_keys) do
    if not (is_list(event_name) and atoms_only?(event_name) and not Enum.empty?(event_name)),
      do: raise(ArgumentError, "event_name must be a non-empty list of atoms")

    if Enum.empty?(event_name), do: raise(ArgumentError, "event_name is empty")

    if not (is_list(attr_keys) and atoms_or_lists_of_atoms_only?(attr_keys)),
      do:
        raise(ArgumentError, "attr_keys must be a list of atoms, including nested lists of atoms")
  end

  defp atoms_or_lists_of_atoms_only?(list) when is_list(list) do
    Enum.all?(list, fn item ->
      (is_list(item) && atoms_or_lists_of_atoms_only?(item)) or is_atom(item)
    end)
  end

  defp atoms_or_lists_of_atoms_only?(item) when is_atom(item) do
    true
  end

  defp atoms_only?(list), do: Enum.all?(list, &is_atom/1)
end
