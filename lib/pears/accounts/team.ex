defmodule Pears.Accounts.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "teams" do
    field :name, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :enabled, :boolean

    timestamps()
  end

  @doc """
  A team changeset for registration.

  It is important to validate the length of both name and password.
  Otherwise databases may truncate the name without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :password])
    |> validate_name()
    |> validate_password()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 160)
    |> unsafe_validate_unique(:name, Pears.Repo)
    |> unique_constraint(:name)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 80)
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  @doc """
  A team changeset for changing the name.

  It requires the name to change otherwise an error is added.
  """
  def name_changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_name()
    |> case do
      %{changes: %{name: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :name, "did not change")
    end
  end

  @doc """
  A team changeset for changing the password.
  """
  def password_changeset(team, attrs) do
    team
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(team) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(team, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no team or the team doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Pears.Accounts.Team{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
