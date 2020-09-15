defmodule Pears.Boundary.TeamSession do
  use GenServer
  use OpenTelemetryDecorator

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

  @decorate trace("team_session.start_session", [:team])
  def start_session(team) do
    GenServer.whereis(via(team.name)) ||
      DynamicSupervisor.start_child(
        Pears.Supervisor.TeamSession,
        {__MODULE__, team}
      )

    {:ok, team}
  end

  @decorate trace("team_session.end_session", [:team_name])
  def end_session(team_name) do
    if session_started?(team_name), do: GenServer.stop(via(team_name))
  end

  @decorate trace("team_session.session_started?", [:team_name])
  def session_started?(team_name) do
    GenServer.whereis(via(team_name)) != nil
  end

  @decorate trace("team_session.get_team", [:team_name])
  def get_team(team_name) do
    GenServer.call(via(team_name), :get_team)
  end

  @decorate trace("team_session.update_team", [:team_name])
  def update_team(team_name, team) do
    GenServer.call(via(team_name), {:update_team, team})
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
end
