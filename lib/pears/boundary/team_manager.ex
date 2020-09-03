defmodule Pears.Boundary.TeamManager do
  use GenServer
  use Pears.O11y.Decorator

  alias Pears.Core.Team

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.merge([name: __MODULE__], options))
  end

  def init(teams) when is_map(teams) do
    {:ok, teams}
  end

  def init(_teams), do: {:error, "teams must be a map"}

  @decorate trace([:team_manager, :validate_name], [:team_name])
  def validate_name(manager \\ __MODULE__, team_name) do
    GenServer.call(manager, {:validate_name, team_name})
  end

  def add_team(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:add_team, name})
  end

  def lookup_team_by_name(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:lookup_team_by_name, name})
  end

  def remove_team(manager \\ __MODULE__, name) do
    GenServer.call(manager, {:remove_team, name})
  end

  @decorate trace([:team_manager, :add_team], [:team_name, :teams, :team, :new_teams])
  def handle_call({:add_team, team_name}, _from, teams) do
    team = Team.new(name: team_name)
    new_teams = Map.put_new(teams, team.name, team)
    {:reply, {:ok, team}, new_teams}
  end

  @decorate trace([:team_manager, :validate_name], [:team_name, :teams])
  def handle_call({:validate_name, team_name}, _from, teams) do
    if Map.has_key?(teams, team_name) do
      {:reply, {:error, :name_taken}, teams}
    else
      {:reply, :ok, teams}
    end
  end

  @decorate trace([:team_manager, :lookup_team_by_name], [:team_name, :teams])
  def handle_call({:lookup_team_by_name, team_name}, _from, teams) do
    if Map.has_key?(teams, team_name) do
      {:reply, {:ok, teams[team_name]}, teams}
    else
      {:reply, {:error, :not_found}, teams}
    end
  end

  @decorate trace([:team_manager, :remove_team], [:team_name, :teams, :new_teams])
  def handle_call({:remove_team, team_name}, _from, teams) do
    new_teams = Map.delete(teams, team_name)
    {:reply, {:ok, new_teams}, new_teams}
  end
end
