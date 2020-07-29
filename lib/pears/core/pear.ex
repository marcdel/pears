defmodule Pears.Core.Pear do
  defstruct name: nil, track: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_track(pear, track) do
    Map.put(pear, :track, track)
  end

  def remove_track(pear) do
    Map.put(pear, :track, nil)
  end
end
