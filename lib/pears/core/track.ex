defmodule Pears.Core.Track do
  defstruct name: nil, id: nil, locked: false, pears: %{}

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def add_pear(track, pear) do
    %{track | pears: Map.put(track.pears, pear.name, pear)}
  end

  def remove_pear(track, pear_name) do
    %{track | pears: Map.delete(track.pears, pear_name)}
  end

  def find_pear(track, pear_name), do: Map.get(track.pears, pear_name, nil)

  def lock_track(track), do: %{track | locked: true}
  def unlock_track(track), do: %{track | locked: false}

  def rename_track(track, new_name), do: %{track | name: new_name}

  def incomplete?(track), do: Enum.count(track.pears) == 1
  def empty?(track), do: Enum.empty?(track.pears)
  def locked?(track), do: track.locked
end
