defmodule Pears.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Pears.Repo
  alias Pears.Accounts.{Team, TeamToken}

  ## Database getters

  @doc """
  Gets a team by name.

  ## Examples

      iex> get_team_by_name("foo@example.com")
      %Team{}

      iex> get_team_by_name("unknown@example.com")
      nil

  """
  def get_team_by_name(name) when is_binary(name) do
    Repo.get_by(Team, name: name)
  end

  @doc """
  Gets a team by name and password.

  ## Examples

      iex> get_team_by_name_and_password("foo@example.com", "correct_password")
      %Team{}

      iex> get_team_by_name_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_team_by_name_and_password(name, password)
      when is_binary(name) and is_binary(password) do
    team = Repo.get_by(Team, name: name)
    if Team.valid_password?(team, password), do: team
  end

  @doc """
  Gets a single team.

  Raises `Ecto.NoResultsError` if the Team does not exist.

  ## Examples

      iex> get_team!(123)
      %Team{}

      iex> get_team!(456)
      ** (Ecto.NoResultsError)

  """
  def get_team!(id), do: Repo.get!(Team, id)

  ## Team registration

  @doc """
  Registers a team.

  ## Examples

      iex> register_team(%{field: value})
      {:ok, %Team{}}

      iex> register_team(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_team(attrs) do
    %Team{}
    |> Team.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team_registration(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_registration(%Team{} = team, attrs \\ %{}) do
    Team.registration_changeset(team, attrs)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the team name.

  ## Examples

      iex> change_team_name(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_name(team, attrs \\ %{}) do
    Team.name_changeset(team, attrs)
  end

  @doc """
  Updates the team name if the given password is valid.

  ## Examples

      iex> update_team_name(team, "valid password", %{name: ...})
      {:ok, %Team{}}

      iex> update_team_name(team, "invalid password", %{name: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_team_name(team, password, attrs) do
    team
    |> Team.name_changeset(attrs)
    |> Team.validate_current_password(password)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the team password.

  ## Examples

      iex> change_team_password(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_password(team, attrs \\ %{}) do
    Team.password_changeset(team, attrs)
  end

  @doc """
  Updates the team password.

  ## Examples

      iex> update_team_password(team, "valid password", %{password: ...})
      {:ok, %Team{}}

      iex> update_team_password(team, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_team_password(team, password, attrs) do
    changeset =
      team
      |> Team.password_changeset(attrs)
      |> Team.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:team, changeset)
    |> Ecto.Multi.delete_all(:tokens, TeamToken.team_and_contexts_query(team, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{team: team}} -> {:ok, team}
      {:error, :team, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_team_session_token(team) do
    {token, team_token} = TeamToken.build_session_token(team)
    Repo.insert!(team_token)
    token
  end

  @doc """
  Gets the team with the given signed token.
  """
  def get_team_by_session_token(token) do
    {:ok, query} = TeamToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(TeamToken.token_and_context_query(token, "session"))
    :ok
  end
end
