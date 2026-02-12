defmodule PearsWeb.Plugs.VerifySlackSignature do
  @moduledoc """
  Verifies incoming Slack webhook requests by checking the `X-Slack-Signature`
  header against an HMAC-SHA256 digest of the request body.

  ## How it works

  1. Reads `X-Slack-Request-Timestamp` and `X-Slack-Signature` headers.
  2. Rejects requests whose timestamp is older than 5 minutes (replay protection).
  3. Computes `HMAC-SHA256(signing_secret, "v0:<timestamp>:<raw_body>")`.
  4. Compares the computed signature against the provided one using a
     constant-time comparison to prevent timing attacks.

  The raw body must be cached in `conn.private[:raw_body]` by
  `PearsWeb.Plugs.CacheRawBody` (configured as the `:body_reader` for
  `Plug.Parsers` in the endpoint).

  ## Configuration

  The signing secret is read from application config:

      config :pears, slack_signing_secret: "your-secret"
  """

  import Plug.Conn

  @behaviour Plug

  @max_age_seconds 300

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, timestamp} <- get_timestamp(conn),
         :ok <- check_timestamp_freshness(timestamp),
         {:ok, signature} <- get_signature(conn),
         {:ok, raw_body} <- get_raw_body(conn),
         :ok <- verify_signature(signing_secret(), timestamp, raw_body, signature) do
      conn
    else
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: reason}))
        |> halt()
    end
  end

  defp get_timestamp(conn) do
    case get_req_header(conn, "x-slack-request-timestamp") do
      [timestamp | _] -> {:ok, timestamp}
      [] -> {:error, "missing timestamp header"}
    end
  end

  defp check_timestamp_freshness(timestamp) do
    case Integer.parse(timestamp) do
      {ts, _} ->
        now = System.system_time(:second)

        if abs(now - ts) <= @max_age_seconds do
          :ok
        else
          {:error, "timestamp too old"}
        end

      :error ->
        {:error, "invalid timestamp"}
    end
  end

  defp get_signature(conn) do
    case get_req_header(conn, "x-slack-signature") do
      [signature | _] -> {:ok, signature}
      [] -> {:error, "missing signature header"}
    end
  end

  defp get_raw_body(conn) do
    case conn.private[:raw_body] do
      nil -> {:error, "raw body not available"}
      body -> {:ok, body}
    end
  end

  defp verify_signature(secret, timestamp, body, expected_signature) do
    basestring = "v0:#{timestamp}:#{body}"

    computed =
      :crypto.mac(:hmac, :sha256, secret, basestring)
      |> Base.encode16(case: :lower)

    computed_signature = "v0=#{computed}"

    if Plug.Crypto.secure_compare(computed_signature, expected_signature) do
      :ok
    else
      {:error, "invalid signature"}
    end
  end

  defp signing_secret do
    Application.fetch_env!(:pears, :slack_signing_secret)
  end
end
