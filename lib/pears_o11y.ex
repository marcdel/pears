defmodule Pears.O11y do
  def set_masked_attribute(key, nil), do: O11y.set_attribute(key, nil)

  def set_masked_attribute(key, value) do
    masked_value = String.replace(value, ~r/./, "*")
    unmasked_value = String.slice(value, -8..-1)
    masked_value = masked_value <> unmasked_value

    O11y.set_attribute(key, masked_value)
  end

  def set_changeset_errors(%Ecto.Changeset{} = changeset) do
    error_string =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
      |> Enum.map(fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
      |> Enum.join(", ")

    O11y.set_error(error_string)
  end
end
