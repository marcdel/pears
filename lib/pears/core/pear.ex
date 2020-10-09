defmodule Pears.Core.Pear do
  defstruct id: nil, name: nil, track: nil, order: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def set_order(pear, order) do
    %{pear | order: order}
  end

  def add_track(pear, track) do
    Map.put(pear, :track, track.name)
  end

  def remove_track(pear) do
    Map.put(pear, :track, nil)
  end
end
