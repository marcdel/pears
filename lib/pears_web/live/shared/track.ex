defmodule PearsWeb.Track do
  use OpenTelemetryDecorator
  use PearsWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, editing_track: nil)}
  end

  @impl true
  @decorate trace("track_live.edit_track_name", include: [:_team_name, :track_name])
  def handle_event("edit-track-name", %{"track-name" => track_name}, socket) do
    _team_name = team_name(socket)
    {:noreply, assign(socket, :editing_track, track_name)}
  end

  @impl true
  @decorate trace("track_live.cancel_editing_track", include: [:_team_name, :_track_name])
  def handle_event("cancel-editing-track", _params, socket) do
    _team_name = team_name(socket)
    _track_name = socket.assigns.editing_track

    {:noreply, cancel_editing_track(socket)}
  end

  @impl true
  @decorate trace("track_live.save_track_name",
              include: [:team_name, :track_name, :new_track_name]
            )
  def handle_event("save-track-name", %{"new-track-name" => new_track_name}, socket) do
    team_name = team_name(socket)
    track_name = socket.assigns.editing_track

    case Pears.rename_track(team_name, track_name, new_track_name) do
      {:ok, _updated_team} ->
        {:noreply, cancel_editing_track(socket)}

      {:error, _changeset} ->
        put_parent_flash(
          team_name,
          :error,
          "Sorry, a track with the name '#{new_track_name}' already exists"
        )

        {:noreply, cancel_editing_track(socket)}
    end
  end

  defp put_parent_flash(team_name, type, message) do
    parent_topic = "#{inspect(Pears)}#{team_name}"
    Phoenix.PubSub.broadcast(Pears.PubSub, parent_topic, {Pears, :put_flash, type, message})
  end

  defp team_name(socket), do: socket.assigns.team_name

  defp cancel_editing_track(socket) do
    assign(socket, :editing_track, nil)
  end
end
