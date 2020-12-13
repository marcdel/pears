defmodule Pears.Boundary.TeamSession do
  use GenServer
  use OpenTelemetryDecorator

  alias Pears.Boundary.TeamManager
  alias Pears.Core.Team
  alias Pears.O11y
  alias Pears.Persistence

  @timeout :timer.minutes(60)

  defmodule State do
    defstruct [:team, :session_facilitator]

    def new(team) do
      %__MODULE__{team: team, session_facilitator: Team.facilitator(team)}
    end

    def update_team(%{session_facilitator: nil} = state, team) do
      state
      |> Map.put(:team, team)
      |> new_session_facilitator()
    end

    def update_team(state, team), do: Map.put(state, :team, team)

    def new_session_facilitator(state) do
      Map.put(state, :session_facilitator, Team.facilitator(state.team))
    end

    def team(state), do: Map.get(state, :team)
    def session_facilitator(state), do: Map.get(state, :session_facilitator)
  end

  def start_link(team) do
    GenServer.start_link(__MODULE__, team, name: via(team.name))
  end

  def child_spec(team) do
    %{
      id: {__MODULE__, team.name},
      start: {__MODULE__, :start_link, [team]},
      restart: :temporary
    }
  end

  @decorate trace("team_session.init", include: [[:team, :name]])
  def init(team) do
    {:ok, State.new(team), @timeout}
  end

  @decorate trace("team_session.find_or_start_session", include: [:team_name])
  def find_or_start_session(team_name) do
    with {:ok, team} <- maybe_fetch_team_from_db(team_name),
         {:ok, team} <- get_or_start_session(team) do
      {:ok, team}
    end
  end

  @decorate trace("team_session.start_session", include: [[:team, :name]])
  def start_session(team) do
    GenServer.whereis(via(team.name)) ||
      DynamicSupervisor.start_child(
        Pears.Supervisor.TeamSession,
        {__MODULE__, team}
      )

    {:ok, team}
  end

  @decorate trace("team_session.end_session", include: [:team_name])
  def end_session(team_name) do
    if session_started?(team_name), do: GenServer.stop(via(team_name))
  end

  @decorate trace("team_session.session_started?", include: [:team_name])
  def session_started?(team_name) do
    GenServer.whereis(via(team_name)) != nil
  end

  @decorate trace("team_session.get_team", include: [:team_name])
  def get_team(team_name) do
    GenServer.call(via(team_name), :get_team)
  end

  @decorate trace("team_session.update_team", include: [:team_name])
  def update_team(team_name, team) do
    GenServer.call(via(team_name), {:update_team, team})
  end

  @decorate trace("team_session.facilitator", include: [:team_name])
  def facilitator(team_name) do
    GenServer.call(via(team_name), :get_facilitator)
  end

  @decorate trace("team_session.new_facilitator", include: [:team_name])
  def new_facilitator(team_name) do
    GenServer.call(via(team_name), :get_new_facilitator)
  end

  @decorate trace("team_session.maybe_fetch_team_from_db", include: [:team_name, :error])
  defp maybe_fetch_team_from_db(team_name) do
    with {:error, :not_found} <- TeamManager.lookup_team_by_name(team_name),
         {:ok, team_record} <- Persistence.get_team_by_name(team_name),
         team <- map_to_team(team_record) do
      {:ok, team}
    else
      {:ok, team} -> {:ok, team}
      error -> error
    end
  end

  defp get_or_start_session(team) do
    get_or_start_session(team, session_started?: session_started?(team.name))
  end

  defp get_or_start_session(team, session_started?: false) do
    start_session(team)
  end

  defp get_or_start_session(%{name: team_name}, session_started?: true) do
    get_team(team_name)
  end

  @decorate trace("team_session.map_to_team", include: [:team_name])
  defp map_to_team(%{name: team_name} = team_record) do
    Team.new(name: team_name)
    |> Team.set_slack_token(team_record.slack_token)
    |> Team.set_slack_channel(team_record.slack_channel)
    |> add_pears(team_record)
    |> add_tracks(team_record)
    |> assign_pears(team_record)
    |> add_history(team_record)
  end

  @decorate trace("team_session.load_history", include: [[:team, :name]])
  defp load_history(team) do
    with {:ok, team_record} <- Persistence.get_team_by_name(team.name),
         updated_team <- add_history(team, team_record) do
      {:ok, updated_team}
    end
  end

  @decorate trace("team_session.add_pears", include: [[:team, :name]])
  defp add_pears(team, team_record) do
    Enum.reduce(team_record.pears, team, fn pear_record, team ->
      Team.add_pear(team, pear_record.name, pear_record.id)
    end)
  end

  @decorate trace("team_session.add_tracks", include: [[:team, :name]])
  defp add_tracks(team, team_record) do
    Enum.reduce(team_record.tracks, team, fn track_record, team ->
      team
      |> Team.add_track(track_record.name, track_record.id)
      |> maybe_lock_track(track_record)
      |> maybe_set_anchor(track_record)
    end)
  end

  @decorate trace("team_session.assign_pears", include: [[:team, :name]])
  defp assign_pears(team, team_record) do
    Enum.reduce(team_record.pears, team, fn pear_record, team ->
      case pear_record.track do
        nil -> team
        _ -> Team.add_pear_to_track(team, pear_record.name, pear_record.track.name)
      end
    end)
  end

  defp maybe_lock_track(team, %{locked: false}), do: team

  defp maybe_lock_track(team, %{locked: true, name: track_name}) do
    Team.lock_track(team, track_name)
  end

  defp maybe_set_anchor(team, %{anchor: nil}), do: team

  defp maybe_set_anchor(team, %{name: track_name, anchor: %{name: pear_name}}) do
    Team.toggle_anchor(team, pear_name, track_name)
  end

  @decorate trace("team_session.add_history", include: [[:team, :name]])
  defp add_history(team, team_record) do
    history =
      Enum.map(team_record.snapshots, fn snapshot ->
        Enum.map(snapshot.matches, fn %{track_name: track_name, pear_names: pear_names} ->
          {track_name, pear_names}
        end)
      end)

    Map.put(team, :history, history)
  end

  def via(name) do
    {:via, Registry, {Pears.Registry.TeamSession, name}}
  end

  def handle_call(:get_team, _from, state) do
    {:reply, {:ok, State.team(state)}, state, @timeout}
  end

  def handle_call({:update_team, updated_team}, _from, state) do
    {:reply, {:ok, updated_team}, State.update_team(state, updated_team), @timeout}
  end

  def handle_call(:get_facilitator, _from, state) do
    {:reply, {:ok, State.session_facilitator(state)}, state, @timeout}
  end

  def handle_call(:get_new_facilitator, _from, state) do
    facilitator =
      state
      |> State.new_session_facilitator()
      |> State.session_facilitator()

    {:reply, {:ok, facilitator}, state, @timeout}
  end

  @decorate trace("team_session.timeout")
  def handle_info(:timeout, state) do
    O11y.set_attribute(:team_name, State.team(state).name)
    {:stop, :normal, []}
  end
end
