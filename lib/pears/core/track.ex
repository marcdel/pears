defmodule Pears.Core.Track do
  defstruct name: nil, pears: []

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(track, pear) do
    %{track | pears: [pear] ++ track.pears}
  end

  def remove_pear(track, pear_name) do
    %{track | pears: Enum.filter(track.pears, fn pear -> pear.name != pear_name end)}
  end
end
