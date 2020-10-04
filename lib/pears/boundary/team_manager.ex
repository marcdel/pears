defmodule Pears.Boundary.TeamManager do
  use GenServer
  use OpenTelemetryDecorator

  alias Pears.Core.Team

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.merge([name: __MODULE__], options))
  end

  def init(teams) when is_map(teams) do
    {:ok, teams}
  end

  def init(_teams), do: {:error, "teams must be a map"}

  @decorate trace("team_manager.validate_name", include: [:team_name])
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

  @decorate trace("team_manager.add_team", include: [:team_name])
  def handle_call({:add_team, team_name}, _from, teams) do
    team = Team.new(name: team_name)
    new_teams = Map.put_new(teams, team.name, team)
    {:reply, {:ok, team}, new_teams}
  end

  @decorate trace("team_manager.validate_name", include: [:team_name])
  def handle_call({:validate_name, team_name}, _from, teams) do
    cond do
      String.trim(team_name) == "" ->
        {:reply, {:error, :name_blank}, teams}

      name_taken?(team_name, teams) ->
        {:reply, {:error, :name_taken}, teams}

      true ->
        {:reply, :ok, teams}
    end
  end

  @decorate trace("team_manager.lookup_team_by_name", include: [:team_name])
  def handle_call({:lookup_team_by_name, team_name}, _from, teams) do
    if Map.has_key?(teams, team_name) do
      {:reply, {:ok, teams[team_name]}, teams}
    else
      {:reply, {:error, :not_found}, teams}
    end
  end

  @decorate trace("team_manager.remove_team", include: [:team_name])
  def handle_call({:remove_team, team_name}, _from, teams) do
    new_teams = Map.delete(teams, team_name)
    {:reply, {:ok, new_teams}, new_teams}
  end

  defp name_taken?(team_name, teams) do
    teams
    |> Map.keys()
    |> Enum.map(&String.downcase/1)
    |> Enum.member?(String.downcase(team_name))
  end
end
