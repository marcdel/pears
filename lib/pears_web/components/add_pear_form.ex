defmodule PearsWeb.AddPearForm do
  use PearsWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, pear_name: "")}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("add_pear", %{"pear-name" => pear_name}, socket) do
    case Pears.add_pear(socket.assigns.team.name, pear_name) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Sorry, a Pear with the name '#{pear_name}' already exists")
         |> push_navigate(to: ~p"/")}
    end
  end
end
