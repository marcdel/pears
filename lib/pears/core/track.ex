defmodule Pears.Core.Track do
  defstruct name: nil, pears: %{}

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(track, pear) do
    %{track | pears: Map.put(track.pears, pear.name, pear)}
  end

  def remove_pear(track, pear_name) do
    %{track | pears: Map.delete(track.pears, pear_name)}
  end
end
