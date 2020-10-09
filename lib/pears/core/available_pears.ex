defmodule Pears.Core.AvailablePears do
  alias Pears.Core.Pear

  defstruct pears: %{}

  def add_pear(available_pears, pear) do
    order = next_pear_order(available_pears)
    pear = Pear.set_order(pear, order)

    Map.put(available_pears, pear.name, pear)
  end

  defp next_pear_order(available_pears) do
    current_max =
      available_pears
      |> Map.values()
      |> Enum.max_by(& &1.order, fn -> %{} end)
      |> Map.get(:order, 0)

    current_max + 1
  end
end
