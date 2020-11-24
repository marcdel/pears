defmodule Pears.Boundary.TeamSession do
  use GenServer
  use OpenTelemetryDecorator

  alias Pears.Core.Team
  alias Pears.O11y

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
