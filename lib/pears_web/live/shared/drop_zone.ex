defmodule PearsWeb.DropZone do
  use PearsWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, track_name: "Unassigned")}
  end

  @impl true
  def update(assigns, socket) do
    new_assigns = Map.put_new(assigns, :track_name, track_name(assigns))
    {:ok, assign(socket, new_assigns)}
  end

  defp track_name(%{track: nil}), do: "Unassigned"
  defp track_name(%{track: track}), do: track.name
end
