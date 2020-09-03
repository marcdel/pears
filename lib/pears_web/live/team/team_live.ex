defmodule PearsWeb.TeamLive do
  use PearsWeb, :live_view
  use Pears.O11y.Decorator

  @impl true
  @decorate trace_decorator([:team_live, :mount], [:team_name])
  def mount(%{"id" => team_name}, _session, socket) do
    {
      :ok,
      socket
      |> assign_team_or_redirect(team_name)
      |> assign(selected_pear: nil, selected_pear_track: nil, editing_track: nil)
      |> apply_action(socket.assigns.live_action)
    }
  end

  @impl true
  @decorate trace_decorator([:team_live, :handle_params], [:team_name, :_params, :_url])
  def handle_params(_params, _url, socket) do
    team_name = team_name(socket)
    if connected?(socket), do: Pears.subscribe(team_name)
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  @decorate trace_decorator([:team_live, :view_helper, :list_tracks], [:team])
  def list_tracks(team) do
    team.tracks
    |> Enum.sort_by(fn {_, %{id: id}} -> id end)
    |> Enum.map(fn {_track_name, track} -> track end)
  end

  @impl true
  @decorate trace_decorator([:team_live, :recommend_pears], [:_params, :_team, :_updated_team])
  def handle_event("recommend-pears", _params, socket) do
    _team = socket.assigns.team
    {_, _updated_team} = Pears.recommend_pears(team_name(socket))
    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator([:team_live, :reset_pears], [:team_name, :_updated_team])
  def handle_event("reset-pears", _params, socket) do
    team_name = team_name(socket)
    {:ok, _updated_team} = Pears.reset_pears(team_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator([:team_live, :remove_track], [:team_name, :track_name, :_updated_team])
  def handle_event("remove-track", %{"track-name" => track_name}, socket) do
    team_name = team_name(socket)
    {:ok, _updated_team} = Pears.remove_track(team_name, track_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator([:team_live, :lock_track], [:team_name, :track_name, :_updated_team])
  def handle_event("lock-track", %{"track-name" => track_name}, socket) do
    team_name = team_name(socket)
    {:ok, _updated_team} = Pears.lock_track(team_name, track_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator([:team_live, :unlock_track], [:team_name, :track_name, :_updated_team])
  def handle_event("unlock-track", %{"track-name" => track_name}, socket) do
    team_name = team_name(socket)
    {:ok, _updated_team} = Pears.unlock_track(team_name, track_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator([:team_live, :edit_track_name], [:team_name, :track_name])
  def handle_event("edit-track-name", %{"track-name" => track_name}, socket) do
    {:noreply, assign(socket, :editing_track, track_name)}
  end

  @impl true
  @decorate trace_decorator(
              [:team_live, :save_track_name],
              [:team_name, :track_name, :new_track_name, :_updated_team, :_changeset]
            )
  def handle_event("save-track-name", %{"new-track-name" => new_track_name}, socket) do
    team_name = team_name(socket)
    track_name = socket.assigns.editing_track

    case Pears.rename_track(team_name, track_name, new_track_name) do
      {:ok, _updated_team} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Sorry, a track with the name '#{new_track_name}' already exists")
         |> cancel_editing_track()}
    end
  end

  @impl true
  @decorate trace_decorator(
              [:team_live, :assigned_pear_selected],
              [:team_name, :pear_name, :track_name]
            )
  def handle_event(
        "pear-selected",
        %{"pear-name" => pear_name, "track-name" => track_name},
        socket
      ) do
    {:noreply, assign(socket, selected_pear: pear_name, selected_pear_track: track_name)}
  end

  @impl true
  @decorate trace_decorator([:team_live, :available_pear_selected], [:team_name, :pear_name])
  def handle_event("pear-selected", %{"pear-name" => pear_name}, socket) do
    {:noreply, assign(socket, selected_pear: pear_name)}
  end

  @impl true
  @decorate trace_decorator([:team_live, :unselect_pear], [:team_name, :_params])
  def handle_event("unselect-pear", _params, socket) do
    {
      :noreply,
      socket
      |> unselect_pear()
      |> cancel_editing_track()
    }
  end

  @impl true
  @decorate trace_decorator(
              [:team_live, :record_pears],
              [:team_name, :_params, :_updated_team, :_changeset]
            )
  def handle_event("record-pears", _params, socket) do
    team_name = team_name(socket)

    case Pears.record_pears(team_name) do
      {:ok, _updated_team} ->
        {:noreply, put_flash(socket, :info, "Today's assigned pears have been recorded!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  @impl true
  @decorate trace_decorator(
              [:team_live, :unassign_pear],
              [:team_name, :_params, :pear_name, :track_name, :_error]
            )
  def handle_event("unassign-pear", _params, socket) do
    team_name = team_name(socket)

    with {:ok, pear_name} <- selected_pear(socket),
         {:ok, track_name} <- selected_track(socket),
         {:ok, _updated_team} <- Pears.remove_pear_from_track(team_name, pear_name, track_name) do
      {:noreply, socket}
    else
      _error ->
        {:noreply, socket}
    end
  end

  @impl true
  @decorate trace_decorator([:team_live, :move_pear], [:_team_name])
  def handle_event("move-pear", %{"from" => "Unassigned", "to" => "Unassigned"}, socket) do
    _team_name = team_name(socket)
    {:noreply, socket}
  end

  @decorate trace_decorator([:team_live, :move_pear], [:team_name, :from_track, :pear_name])
  def handle_event(
        "move-pear",
        %{"from" => from_track, "to" => "Unassigned", "pear" => pear_name},
        socket
      ) do
    team_name = team_name(socket)
    Pears.remove_pear_from_track(team_name, pear_name, from_track)

    {:noreply, socket}
  end

  @decorate trace_decorator([:team_live, :move_pear], [:team_name, :to_track, :pear_name])
  def handle_event(
        "move-pear",
        %{"from" => "Unassigned", "to" => to_track, "pear" => pear_name},
        socket
      ) do
    team_name = team_name(socket)
    Pears.add_pear_to_track(team_name, pear_name, to_track)

    {:noreply, socket}
  end

  @decorate trace_decorator(
              [:team_live, :move_pear],
              [:team_name, :from_track, :to_track, :pear_name]
            )
  def handle_event(
        "move-pear",
        %{"from" => from_track, "to" => to_track, "pear" => pear_name},
        socket
      ) do
    team_name = team_name(socket)
    Pears.move_pear_to_track(team_name, pear_name, from_track, to_track)

    {:noreply, socket}
  end

  @impl true
  @decorate trace_decorator(
              [:team_live, :track_clicked],
              [:team_name, :to_track, :pear_name, :_updated_team, :_error]
            )
  def handle_event("track-clicked", %{"track-name" => to_track}, socket) do
    team_name = team_name(socket)

    from_track =
      if socket.assigns.selected_pear_track == "Unassigned" do
        nil
      else
        socket.assigns.selected_pear_track
      end

    with {:ok, pear_name} <- selected_pear(socket),
         {:ok, _updated_team} <-
           Pears.move_pear_to_track(team_name, pear_name, from_track, to_track) do
      {:noreply, unselect_pear(socket)}
    else
      _error ->
        {:noreply, unselect_pear(socket)}
    end
  end

  @impl true
  @decorate trace_decorator([:team_live, :team_updated], [:team])
  def handle_info({Pears, [:team, :updated], team}, socket) do
    {:noreply, assign(socket, team: team)}
  end

  defp team(socket), do: socket.assigns.team
  defp team_name(socket), do: team(socket).name

  defp selected_pear(socket) do
    case socket.assigns.selected_pear do
      nil -> {:error, :none_selected}
      pear_name -> {:ok, pear_name}
    end
  end

  defp selected_track(socket) do
    case socket.assigns.selected_pear_track do
      nil -> {:error, :none_selected}
      track_name -> {:ok, track_name}
    end
  end

  defp unselect_pear(socket) do
    assign(socket, selected_pear: nil, selected_pear_track: nil)
  end

  defp cancel_editing_track(socket) do
    assign(socket, :editing_track, nil)
  end

  defp assign_team_or_redirect(socket, team_name) do
    case Pears.lookup_team_by(name: team_name) do
      {:ok, team} ->
        assign(socket, :team, team)

      {:error, :not_found} ->
        socket
        |> push_redirect(to: Routes.page_path(socket, :index))
        |> put_flash(:error, "Sorry, that team was not found")
    end
  end

  defp apply_action(socket, :show), do: socket
  defp apply_action(socket, :add_pear), do: socket
  defp apply_action(socket, :add_track), do: socket
end
