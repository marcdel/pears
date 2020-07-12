defmodule Pears.Boundary.TeamManager do
  use GenServer

  alias Pears.Core.Team

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.merge([name: __MODULE__], options))
  end

  def init(teams) when is_map(teams) do
    {:ok, teams}
  end

  def init(_teams), do: {:error, "teams must be a map"}

  def validate_name(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:validate_name, name})
  end

  def add_team(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:add_team, name})
  end

  def lookup_team_by_name(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:lookup_team_by_name, name})
  end

  def update_team(manager \\ __MODULE__, team) do
    GenServer.call(manager, {:update_team, team})
  end

  def remove_team(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:remove_team, name})
  end

  def handle_call({:add_team, name}, _from, teams) do
    team = Team.new(name: name)
    new_teams = Map.put_new(teams, team.name, team)
    {:reply, {:ok, team}, new_teams}
  end

  def handle_call({:validate_name, name}, _from, teams) do
    if Map.has_key?(teams, name) do
      {:reply, {:error, :name_taken}, teams}
    else
      {:reply, :ok, teams}
    end
  end

  def handle_call({:lookup_team_by_name, name}, _from, teams) do
    if Map.has_key?(teams, name) do
      {:reply, {:ok, teams[name]}, teams}
    else
      {:reply, {:error, :not_found}, teams}
    end
  end

  def handle_call({:update_team, team}, _from, teams) do
    new_teams = Map.put(teams, team.name, team)
    {:reply, {:ok, team}, new_teams}
  end

  def handle_call({:remove_team, name}, _from, teams) do
    new_teams = Map.delete(teams, name)
    {:reply, {:ok, new_teams}, new_teams}
  end
end
