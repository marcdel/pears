defmodule PearsWeb.TeamAuth do
  use OpenTelemetryDecorator

  import Plug.Conn
  import Phoenix.Controller

  alias Pears.Accounts
  alias PearsWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in TeamToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "team_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the team in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  @decorate trace("team_auth.log_in_team", include: [[:team, :name], :team_return_to])
  def log_in_team(conn, team, params \\ %{}) do
    token = Accounts.generate_team_session_token(team)
    team_return_to = get_session(conn, :team_return_to)

    conn =
      conn
      |> renew_session()
      |> put_session(:team_token, token)
      |> fetch_current_team()
      |> put_session(:live_socket_id, "teams_sessions:#{Base.url_encode64(token)}")
      |> maybe_write_remember_me_cookie(token, params)

    redirect(conn, to: team_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the team out.

  It clears all session data for safety. See renew_session.
  """
  @decorate trace("team_auth.log_out_team", include: [[:team, :name]])
  def log_out_team(conn) do
    _team = team(conn)

    team_token = get_session(conn, :team_token)
    team_token && Accounts.delete_session_token(team_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      PearsWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: Routes.team_session_path(conn, :create))
  end

  @doc """
  Authenticates the team by looking into the session
  and remember me token.
  """
  @decorate trace("team_auth.fetch_current_team", include: [[:team, :name]])
  def fetch_current_team(conn, _opts \\ []) do
    {team_token, conn} = ensure_team_token(conn)
    team = team_token && Accounts.get_team_by_session_token(team_token)
    assign(conn, :current_team, team)
  end

  defp ensure_team_token(conn) do
    if team_token = get_session(conn, :team_token) do
      {team_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if team_token = conn.cookies[@remember_me_cookie] do
        {team_token, put_session(conn, :team_token, team_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the team to not be authenticated.
  """
  @decorate trace("team_auth.redirect_if_team_is_authenticated", include: [[:team, :name]])
  def redirect_if_team_is_authenticated(conn, _opts) do
    team = team(conn)

    if team do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the team to be authenticated.

  If you want to enforce the team email is confirmed before
  they use the application at all, here would be a good place.
  """
  @decorate trace("team_auth.require_authenticated_team", include: [[:team, :name]])
  def require_authenticated_team(conn, _opts) do
    team = team(conn)

    if team do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.team_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    %{request_path: request_path, query_string: query_string} = conn
    return_to = if query_string == "", do: request_path, else: request_path <> "?" <> query_string
    put_session(conn, :team_return_to, return_to)
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(conn) do
    team_name =
      conn
      |> team()
      |> Map.get(:name)

    Routes.team_path(conn, :show, team_name)
  end

  defp team(conn), do: conn.assigns[:current_team]
end
