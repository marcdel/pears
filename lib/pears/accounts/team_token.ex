defmodule Pears.Accounts.TeamToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the name may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_name_validity_in_days 7
  @session_validity_in_days 60

  schema "teams_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :team, Pears.Accounts.Team

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.
  """
  def build_session_token(team) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %Pears.Accounts.TeamToken{token: token, context: "session", team_id: team.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the team found by the token.
  """
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: team in assoc(token, :team),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: team

    {:ok, query}
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the team name while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as teams don't change
  their name.
  """
  def build_name_token(team, context) do
    build_hashed_token(team, context)
  end

  defp build_hashed_token(team, context) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Pears.Accounts.TeamToken{
       token: hashed_token,
       context: context,
       team_id: team.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the team found by the token.
  """
  def verify_name_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: team in assoc(token, :team),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == team.name,
            select: team

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the team token record.
  """
  def verify_change_name_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_name_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the given token with the given context.
  """
  def token_and_context_query(token, context) do
    from Pears.Accounts.TeamToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given team for the given contexts.
  """
  def team_and_contexts_query(team, :all) do
    from t in Pears.Accounts.TeamToken, where: t.team_id == ^team.id
  end

  def team_and_contexts_query(team, [_ | _] = contexts) do
    from t in Pears.Accounts.TeamToken, where: t.team_id == ^team.id and t.context in ^contexts
  end
end
