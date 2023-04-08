defmodule Pears.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Pears.Repo

  alias Pears.Accounts.{Team, TeamToken, TeamNotifier}

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
  Gets a team by email.

  ## Examples

      iex> get_team_by_email("foo@example.com")
      %Team{}

      iex> get_team_by_email("unknown@example.com")
      nil

  """
  def get_team_by_email(email) when is_binary(email) do
    Repo.get_by(Team, email: email)
  end

  @doc """
  Gets a team by email and password.

  ## Examples

      iex> get_team_by_email_and_password("foo@example.com", "correct_password")
      %Team{}

      iex> get_team_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_team_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    team = Repo.get_by(Team, email: email)
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
    Team.registration_changeset(team, attrs, hash_password: false, validate_name: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the team name.

  ## Examples

      iex> change_team_name(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_name(team, attrs \\ %{}) do
    Team.name_changeset(team, attrs, validate_name: false)
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
  Returns an `%Ecto.Changeset{}` for changing the team email.

  ## Examples

      iex> change_team_email(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_email(team, attrs \\ %{}) do
    Team.email_changeset(team, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_team_email(team, "valid password", %{email: ...})
      {:ok, %Team{}}

      iex> apply_team_email(team, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_team_email(team, password, attrs) do
    team
    |> Team.email_changeset(attrs)
    |> Team.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the team email using the given token.

  If the token matches, the team email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_team_email(team, token) do
    context = "change:#{team.email}"

    with {:ok, query} <- TeamToken.verify_change_email_token_query(token, context),
         %TeamToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(team_email_multi(team, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp team_email_multi(team, email, context) do
    changeset =
      team
      |> Team.email_changeset(%{email: email})
      |> Team.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:team, changeset)
    |> Ecto.Multi.delete_all(:tokens, TeamToken.team_and_contexts_query(team, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given team.

  ## Examples

      iex> deliver_team_update_email_instructions(team, current_email, &url(~p"/teams/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_team_update_email_instructions(%Team{} = team, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, team_token} = TeamToken.build_email_token(team, "change:#{current_email}")

    Repo.insert!(team_token)
    TeamNotifier.deliver_update_email_instructions(team, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the team password.

  ## Examples

      iex> change_team_password(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team_password(team, attrs \\ %{}) do
    Team.password_changeset(team, attrs, hash_password: false)
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
  def delete_team_session_token(token) do
    Repo.delete_all(TeamToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given team.

  ## Examples

      iex> deliver_team_confirmation_instructions(team, &url(~p"/teams/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_team_confirmation_instructions(confirmed_team, &url(~p"/teams/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_team_confirmation_instructions(%Team{} = team, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if team.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, team_token} = TeamToken.build_email_token(team, "confirm")
      Repo.insert!(team_token)
      TeamNotifier.deliver_confirmation_instructions(team, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a team by the given token.

  If the token matches, the team account is marked as confirmed
  and the token is deleted.
  """
  def confirm_team(token) do
    with {:ok, query} <- TeamToken.verify_email_token_query(token, "confirm"),
         %Team{} = team <- Repo.one(query),
         {:ok, %{team: team}} <- Repo.transaction(confirm_team_multi(team)) do
      {:ok, team}
    else
      _ -> :error
    end
  end

  defp confirm_team_multi(team) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:team, Team.confirm_changeset(team))
    |> Ecto.Multi.delete_all(:tokens, TeamToken.team_and_contexts_query(team, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given team.

  ## Examples

      iex> deliver_team_reset_password_instructions(team, &url(~p"/teams/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_team_reset_password_instructions(%Team{} = team, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, team_token} = TeamToken.build_email_token(team, "reset_password")
    Repo.insert!(team_token)
    TeamNotifier.deliver_reset_password_instructions(team, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the team by reset password token.

  ## Examples

      iex> get_team_by_reset_password_token("validtoken")
      %Team{}

      iex> get_team_by_reset_password_token("invalidtoken")
      nil

  """
  def get_team_by_reset_password_token(token) do
    with {:ok, query} <- TeamToken.verify_email_token_query(token, "reset_password"),
         %Team{} = team <- Repo.one(query) do
      team
    else
      _ -> nil
    end
  end

  @doc """
  Resets the team password.

  ## Examples

      iex> reset_team_password(team, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Team{}}

      iex> reset_team_password(team, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_team_password(team, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:team, Team.password_changeset(team, attrs))
    |> Ecto.Multi.delete_all(:tokens, TeamToken.team_and_contexts_query(team, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{team: team}} -> {:ok, team}
      {:error, :team, changeset, _} -> {:error, changeset}
    end
  end
end
