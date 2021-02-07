defmodule PearsWeb.TeamLive do
  use OpenTelemetryDecorator
  use PearsWeb, :live_view

  alias Pears.Accounts
  alias Pears.Slack

  @impl true
  @decorate trace("team_live.mount", include: [:team_name])
  def mount(%{"id" => team_name}, session, socket) do
    {
      :ok,
      socket
      |> assign_new(:logged_in_team, fn -> find_logged_in_team(session) end)
      |> assign_team_or_redirect(team_name)
      |> assign(selected_pear: nil, selected_pear_current_location: nil, editing_track: nil)
      |> apply_action(socket.assigns.live_action)
    }
  end

  @impl true
  @decorate trace("team_live.handle_params", include: [:team_name, :_params, :_url])
  def handle_params(_params, _url, socket) do
    team_name = team_name(socket)
    if connected?(socket), do: Pears.subscribe(team_name)
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  def hide_reset_button?(team) do
    FeatureFlags.enabled?(:hide_reset_button, for: team)
  end

  def new_drag_n_drop?(team) do
    FeatureFlags.enabled?(:new_drag_n_drop, for: team)
  end

  def list_tracks(team) do
    team.tracks
    |> Enum.sort_by(fn {_, %{id: id}} -> id end)
    |> Enum.map(fn {_track_name, track} -> track end)
  end

  def list_pears(pears) do
    pears
    |> Enum.sort_by(fn {_, %{order: order}} -> order end)
    |> Enum.map(fn {_pear_name, pear} -> pear end)
  end

  defp show_random_facilitator_message(team) do
    FeatureFlags.enabled?(:random_facilitator, for: team) &&
      Pears.has_active_pears?(team.name)
  end

  @impl true
  @decorate trace("team_live.recommend_pears", include: [:team_name])
  def handle_event("recommend-pears", _params, socket) do
    team_name = team_name(socket)
    {_, _updated_team} = Pears.recommend_pears(team_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace("team_live.reset_pears", include: [:team_name])
  def handle_event("reset-pears", _params, socket) do
    team_name = team_name(socket)
    {:ok, _updated_team} = Pears.reset_pears(team_name)
    {:noreply, socket}
  end

  @impl true
  @decorate trace("team_live.record_pears", include: [:team_name])
  def handle_event("record-pears", _params, socket) do
    team_name = team_name(socket)

    case Pears.record_pears(team_name) do
      {:ok, _updated_team} ->
        Slack.send_daily_pears_summary(team_name)
        {:noreply, put_flash(socket, :info, "Today's assigned pears have been recorded!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Sorry! Something went wrong, please try again.")}
    end
  end

  @impl true
  @decorate trace("team_live.pear_selected", include: [:_team_name, :pear_name, :current_location])
  def handle_event("pear-selected", params, socket) do
    _team_name = team_name(socket)
    pear_name = Map.get(params, "pear-name")
    current_location = Map.get(params, "current-location")
    {:noreply, select_pear(socket, pear_name, current_location)}
  end

  @impl true
  @decorate trace("team_live.pear_unselected",
              include: [:_team_name, :_pear_name, :_current_location]
            )
  def handle_event("pear-unselected", params, socket) do
    _team_name = team_name(socket)
    _pear_name = Map.get(params, "pear-name")
    _current_location = Map.get(params, "current-location")

    {:noreply, unselect_pear(socket)}
  end

  @impl true
  @decorate trace("team_live.drag_pear", include: [:_team_name, :pear_name, :current_location])
  def handle_event("drag-pear", params, socket) do
    _team_name = team_name(socket)
    pear_name = Map.get(params, "pear-name")
    current_location = Map.get(params, "current-location")
    {:noreply, select_pear(socket, pear_name, current_location)}
  end

  @impl true
  @decorate trace("team_live.destination_selected",
              include: [:team_name, :pear_name, :current_location, :destination]
            )
  def handle_event("destination-selected", %{"destination" => destination}, socket) do
    team_name = team_name(socket)
    pear_name = selected_pear(socket)
    current_location = current_location(socket)

    case {current_location, destination} do
      {"Unassigned", "Unassigned"} ->
        nil

      {_, "Trash"} ->
        Pears.remove_pear(team_name, pear_name)

      {"Unassigned", destination} ->
        Pears.add_pear_to_track(team_name, pear_name, destination)

      {current_location, "Unassigned"} ->
        Pears.remove_pear_from_track(team_name, pear_name, current_location)

      {current_location, destination} ->
        Pears.move_pear_to_track(team_name, pear_name, current_location, destination)
    end

    {:noreply, unselect_pear(socket)}
  end

  @impl true
  @decorate trace("team_live.move_pear", include: [:_team_name])
  def handle_event("move-pear", %{"from" => "Unassigned", "to" => "Unassigned"}, socket) do
    _team_name = team_name(socket)

    {:noreply, unselect_pear(socket)}
  end

  @decorate trace("team_live.move_pear", include: [:team_name, :pear_name, :from_track])
  def handle_event("move-pear", %{"to" => "Unassigned"} = params, socket) do
    team_name = team_name(socket)
    pear_name = Map.get(params, "pear")
    from_track = Map.get(params, "from")

    Pears.remove_pear_from_track(team_name, pear_name, from_track)

    {:noreply, unselect_pear(socket)}
  end

  @decorate trace("team_live.move_pear", include: [:team_name, :pear_name])
  def handle_event("move-pear", %{"to" => "Trash"} = params, socket) do
    team_name = team_name(socket)
    pear_name = Map.get(params, "pear")

    Pears.remove_pear(team_name, pear_name)

    {:noreply, unselect_pear(socket)}
  end

  @decorate trace("team_live.move_pear", include: [:team_name, :pear_name, :to_track])
  def handle_event("move-pear", %{"from" => "Unassigned"} = params, socket) do
    team_name = team_name(socket)
    pear_name = Map.get(params, "pear")
    to_track = Map.get(params, "to")

    Pears.add_pear_to_track(team_name, pear_name, to_track)

    {:noreply, unselect_pear(socket)}
  end

  @decorate trace("team_live.move_pear", include: [:team_name, :pear_name, :from_track, :to_track])
  def handle_event("move-pear", params, socket) do
    team_name = team_name(socket)
    pear_name = Map.get(params, "pear")
    from_track = Map.get(params, "from")
    to_track = Map.get(params, "to")

    Pears.move_pear_to_track(team_name, pear_name, from_track, to_track)

    {:noreply, unselect_pear(socket)}
  end

  @impl true
  @decorate trace("team_live.move_pear.failed", include: [:_team_name, :_params])
  def handle_event("move-pear", _params, socket) do
    _team_name = team_name(socket)
    {:noreply, unselect_pear(socket)}
  end

  @impl true
  def handle_info({Pears, [:team, :updated], team}, socket) do
    {:noreply, assign(socket, team: team)}
  end

  @impl true
  def handle_info({Pears, :put_flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  defp team(socket), do: socket.assigns.team
  defp team_name(socket), do: team(socket).name
  defp selected_pear(socket), do: socket.assigns.selected_pear
  defp current_location(socket), do: socket.assigns.selected_pear_current_location

  defp select_pear(socket, pear_name, current_location) do
    assign(socket, selected_pear: pear_name, selected_pear_current_location: current_location)
  end

  defp unselect_pear(socket) do
    assign(socket, selected_pear: nil, selected_pear_current_location: nil)
  end

  defp assign_team_or_redirect(socket, team_name) do
    with true <- is_logged_in_team(socket, team_name),
         {:ok, team} <- Pears.lookup_team_by(name: team_name) do
      assign(socket, team: team, page_title: team.name)
    else
      _ ->
        socket
        |> put_flash(:error, "Sorry, that team was not found")
        |> redirect(to: Routes.team_registration_path(socket, :new))
    end
  end

  defp is_logged_in_team(socket, team_name) do
    socket.assigns[:logged_in_team].name == team_name
  end

  defp find_logged_in_team(session) do
    case Accounts.get_team_by_session_token(session["team_token"]) do
      %{} = user -> user
      _ -> nil
    end
  end

  defp apply_action(socket, :show), do: socket
  defp apply_action(socket, :add_pear), do: socket
  defp apply_action(socket, :add_track), do: socket
end
