defmodule Pears.Boundary.TeamSession do
  use GenServer

  alias Pears.Core.{Recommendator, Team}

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

  def start_session(team) do
    GenServer.whereis(via(team.name)) ||
      DynamicSupervisor.start_child(
        Pears.Supervisor.TeamSession,
        {__MODULE__, team}
      )

    {:ok, team}
  end

  def end_session(name) do
    GenServer.stop(via(name))
  end

  def session_started?(name) do
    GenServer.whereis(via(name)) != nil
  end

  def get_team(team_name) do
    GenServer.call(via(team_name), :get_team)
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

  def add_pear_to_track(team_name, pear_name, track_name) do
    GenServer.call(via(team_name), {:add_pear_to_track, pear_name, track_name})
  end

  def move_pear_to_track(team_name, pear_name, from_track_name, to_track_name) do
    GenServer.call(
      via(team_name),
      {:move_pear_to_track, pear_name, from_track_name, to_track_name}
    )
  end

  def make_pear_unavailable(team_name, pear_name) do
    GenServer.call(via(team_name), {:make_pear_unavailable, pear_name})
  end

  def remove_pear_from_track(team_name, pear_name, track_name) do
    GenServer.call(via(team_name), {:remove_pear_from_track, pear_name, track_name})
  end

  def recommend_pears(team_name) do
    GenServer.call(via(team_name), :recommend_pears)
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

  def handle_call({:add_pear_to_track, pear_name, track_name}, _from, team) do
    with %{name: ^pear_name} <- Team.find_available_pear(team, pear_name),
         %{name: ^track_name} <- Team.find_track(team, track_name) do
      team = Team.add_pear_to_track(team, pear_name, track_name)
      {:reply, {:ok, team}, team}
    else
      _ -> {:reply, {:error, :not_found}, team}
    end
  end

  def handle_call({:move_pear_to_track, pear_name, nil, to_track_name}, _from, team) do
    with %{name: ^pear_name} <- Team.find_available_pear(team, pear_name),
         %{name: ^to_track_name} <- Team.find_track(team, to_track_name) do
      team = Team.add_pear_to_track(team, pear_name, to_track_name)
      {:reply, {:ok, team}, team}
    else
      _ ->
        {:reply, {:error, :not_found}, team}
    end
  end

  def handle_call({:move_pear_to_track, pear_name, from_track_name, to_track_name}, _from, team) do
    with %{name: ^pear_name} <- Team.find_assigned_pear(team, pear_name),
         %{name: ^from_track_name} <- Team.find_track(team, from_track_name),
         %{name: ^to_track_name} <- Team.find_track(team, to_track_name) do
      team = Team.move_pear_to_track(team, pear_name, from_track_name, to_track_name)
      {:reply, {:ok, team}, team}
    else
      _ ->
        {:reply, {:error, :not_found}, team}
    end
  end

  def handle_call({:remove_pear_from_track, pear_name, track_name}, _from, team) do
    with %{name: ^pear_name} <- Team.find_assigned_pear(team, pear_name),
         %{name: ^track_name} <- Team.find_track(team, track_name) do
      team = Team.remove_pear_from_track(team, pear_name, track_name)
      {:reply, {:ok, team}, team}
    else
      _ -> {:reply, {:error, :not_found}, team}
    end
  end

  def handle_call({:make_pear_unavailable, pear_name}, _from, team) do
    case Team.find_pear(team, pear_name) do
      %{name: ^pear_name} ->
        team = Team.make_pear_unavailable(team, pear_name)
        {:reply, {:ok, team}, team}

      _ ->
        {:reply, {:error, :not_found}, team}
    end
  end

  def handle_call(:recommend_pears, _from, team) do
    team = Recommendator.assign_pears(team)
    {:reply, {:ok, team}, team}
  end

  def handle_call(:record_pears, _from, team) do
    team = Team.record_pears(team)
    {:reply, {:ok, team}, team}
  end
end
