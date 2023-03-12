defmodule Pears.Core.AvailablePears do
  use OpenTelemetryDecorator

  alias Pears.Core.Pear

  defstruct pears: %{}

  def add_pears(available_pears, pears) when is_map(pears) do
    pears
    |> Map.values()
    |> Enum.reduce(available_pears, fn pear, available_pears ->
      add_pear(available_pears, pear)
    end)
  end

  @decorate trace("available_pears.add_pear", include: [:available_pears, :pear, :order])
  def add_pear(available_pears, pear) do
    order = next_pear_order(available_pears)
    pear = Pear.set_order(pear, order)

    Map.put(available_pears, pear.name, pear)
  end

  defp next_pear_order(available_pears) when available_pears == %{}, do: 1

  defp next_pear_order(available_pears) do
    current_max =
      available_pears
      |> Map.values()
      |> Enum.map(fn
        %{order: nil} -> 0
        %{order: order} -> order
      end)
      |> Enum.max()

    current_max + 1
  end
end
