defmodule PearsWeb.FacilitatorMessage do
  use PearsWeb, :live_component

  @impl true
  def preload([assigns]) do
    {:ok, facilitator} = Pears.facilitator(assigns.team_name)
    [Map.put(assigns, :facilitator, facilitator.name)]
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
