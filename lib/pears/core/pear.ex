defmodule Pears.Core.Pear do
  defstruct id: nil, name: nil, track: nil, order: nil, slack_id: nil, slack_name: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def update(pear, params) do
    struct!(pear, params)
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
