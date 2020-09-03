defmodule Pears.Boundary.TeamSession do
  use GenServer
  use Pears.O11y.Decorator

  alias Pears.Core.Team

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

  def init(team) do
    {:ok, team}
  end

  @decorate trace([:team_session, :start_session], [:team])
  def start_session(team) do
    GenServer.whereis(via(team.name)) ||
      DynamicSupervisor.start_child(
        Pears.Supervisor.TeamSession,
        {__MODULE__, team}
      )

    {:ok, team}
  end

  @decorate trace([:team_session, :end_session], [:team_name])
  def end_session(team_name) do
    if session_started?(team_name), do: GenServer.stop(via(team_name))
  end

  @decorate trace([:team_session, :session_started?], [:team_name])
  def session_started?(team_name) do
    GenServer.whereis(via(team_name)) != nil
  end

  @decorate trace([:team_session, :get_team], [:team_name])
  def get_team(team_name) do
    GenServer.call(via(team_name), :get_team)
  end

  @decorate trace([:team_session, :update_team], [:team_name, :team])
  def update_team(team_name, team) do
    GenServer.call(via(team_name), {:update_team, team})
  end

  def add_pear(team_name, pear_name) do
    GenServer.call(via(team_name), {:add_pear, pear_name})
  end

  def add_track(team_name, track_name) do
    GenServer.call(via(team_name), {:add_track, track_name})
  end

  def remove_track(team_name, track_name) do
    GenServer.call(via(team_name), {:remove_track, track_name})
  end

  def record_pears(team_name) do
    GenServer.call(via(team_name), :record_pears)
  end

  def via(name) do
    {:via, Registry, {Pears.Registry.TeamSession, name}}
  end

  def handle_call(:get_team, _from, team) do
    {:reply, {:ok, team}, team}
  end

  def handle_call({:update_team, updated_team}, _from, _team) do
    {:reply, {:ok, updated_team}, updated_team}
  end

  def handle_call({:add_pear, pear_name}, _from, team) do
    team = Team.add_pear(team, pear_name)
    {:reply, {:ok, team}, team}
  end

  def handle_call({:add_track, track_name}, _from, team) do
    team = Team.add_track(team, track_name)
    {:reply, {:ok, team}, team}
  end

  def handle_call({:remove_track, track_name}, _from, team) do
    team = Team.remove_track(team, track_name)
    {:reply, {:ok, team}, team}
  end

  def handle_call(:record_pears, _from, team) do
    team = Team.record_pears(team)
    {:reply, {:ok, team}, team}
  end
end
