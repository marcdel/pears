defmodule PearsWeb.Plugs.CacheRawBody do
  @moduledoc """
  A custom body reader that caches the raw request body in `conn.private[:raw_body]`.

  Used as the `:body_reader` option for `Plug.Parsers` so that downstream plugs
  (e.g. Slack signature verification) can access the unparsed body.
  """

  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        existing = conn.private[:raw_body] || ""
        conn = Plug.Conn.put_private(conn, :raw_body, existing <> body)
        {:ok, body, conn}

      {:more, body, conn} ->
        existing = conn.private[:raw_body] || ""
        conn = Plug.Conn.put_private(conn, :raw_body, existing <> body)
        {:more, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
