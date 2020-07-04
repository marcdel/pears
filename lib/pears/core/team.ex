defmodule Pears.Core.Team do
  defstruct name: nil, pears: []

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(team, pear) do
    Map.put(team, :pears, [pear] ++ team.pears)
  end
end
