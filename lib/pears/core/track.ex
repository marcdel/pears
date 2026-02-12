defmodule Pears.Core.Track do
  alias Pears.Core.Pear

  defstruct id: nil, name: nil, locked: false, pears: %{}, anchor: nil

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(track, pear) do
    order = next_pear_order(track)
    pear = Pear.set_order(pear, order)

    %{track | pears: Map.put(track.pears, pear.name, pear)}
  end

  def remove_pear(track, pear_name) do
    track = %{track | pears: Map.delete(track.pears, pear_name)}

    if track.anchor == pear_name do
      %{track | anchor: nil}
    else
      track
    end
  end

  def find_pear(track, pear_name), do: Map.get(track.pears, pear_name, nil)

  def choose_anchor(%{anchor: anchor} = track) when anchor != nil, do: track

  def choose_anchor(%{pears: pears} = track) when map_size(pears) == 0, do: track

  def choose_anchor(track) do
    {pear_name, _} = Enum.random(track.pears)
    toggle_anchor(track, pear_name)
  end

  def toggle_anchor(track, pear_name) do
    if track.anchor == pear_name do
      Map.put(track, :anchor, nil)
    else
      Map.put(track, :anchor, pear_name)
    end
  end

  def lock_track(track), do: %{track | locked: true}
  def unlock_track(track), do: %{track | locked: false}

  def rename_track(track, new_name), do: %{track | name: new_name}

  def incomplete?(track), do: Enum.count(track.pears) == 1
  def empty?(track), do: Enum.empty?(track.pears)
  def locked?(track), do: track.locked
  def unlocked?(track), do: !track.locked

  defp next_pear_order(track) do
    current_max =
      track.pears
      |> Map.values()
      |> Enum.max_by(& &1.order, fn -> %{} end)
      |> Map.get(:order, 0)

    current_max + 1
  end
end
