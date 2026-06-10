defmodule PearsWeb.SlackInteractionControllerTest do
  use PearsWeb.ConnCase, async: true

  defp sign_request(conn, body, opts \\ []) do
    timestamp = Keyword.get_lazy(opts, :timestamp, fn -> System.system_time(:second) end)
    timestamp = to_string(timestamp)
    secret = Application.fetch_env!(:pears, :slack_signing_secret)
    basestring = "v0:#{timestamp}:#{body}"

    signature =
      :crypto.mac(:hmac, :sha256, secret, basestring)
      |> Base.encode16(case: :lower)

    conn
    |> put_req_header("x-slack-request-timestamp", timestamp)
    |> put_req_header("x-slack-signature", "v0=#{signature}")
  end

  defp valid_body do
    URI.encode_query(%{"payload" => Jason.encode!(%{"actions" => []})})
  end

  defp post_interaction(conn, body) do
    conn
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> post(~p"/api/slack/interactions", body)
  end

  describe "POST /slack/interactions" do
    test "returns 200 when successfully decodes payload", %{conn: conn} do
      body = URI.encode_query(%{"payload" => Jason.encode!(%{"actions" => []})})

      conn =
        conn
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> sign_request(body)
        |> post(~p"/api/slack/interactions", body)

      assert json_response(conn, 200)
    end

    test "returns 400 when unsuccessfully decodes payload", %{conn: conn} do
      body = URI.encode_query(%{"payload" => ""})

      conn =
        conn
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> sign_request(body)
        |> post(~p"/api/slack/interactions", body)

      assert json_response(conn, 400)
    end
  end

  describe "POST /slack/interactions signature verification rejections" do
    test "returns 401 and halts when timestamp header is missing", %{conn: conn} do
      body = valid_body()

      conn =
        conn
        |> sign_request(body)
        |> delete_req_header("x-slack-request-timestamp")
        |> post_interaction(body)

      assert json_response(conn, 401) == %{"error" => "missing timestamp header"}
      assert conn.halted
    end

    test "returns 401 and halts when timestamp is not an integer", %{conn: conn} do
      body = valid_body()

      conn =
        conn
        |> sign_request(body)
        |> put_req_header("x-slack-request-timestamp", "not-a-timestamp")
        |> post_interaction(body)

      assert json_response(conn, 401) == %{"error" => "invalid timestamp"}
      assert conn.halted
    end

    test "returns 401 and halts when timestamp is older than five minutes", %{conn: conn} do
      body = valid_body()
      stale_timestamp = System.system_time(:second) - 301

      conn =
        conn
        |> sign_request(body, timestamp: stale_timestamp)
        |> post_interaction(body)

      assert json_response(conn, 401) == %{"error" => "timestamp too old"}
      assert conn.halted
    end

    test "returns 401 and halts when timestamp is more than five minutes in the future",
         %{conn: conn} do
      body = valid_body()
      future_timestamp = System.system_time(:second) + 301

      conn =
        conn
        |> sign_request(body, timestamp: future_timestamp)
        |> post_interaction(body)

      assert json_response(conn, 401) == %{"error" => "timestamp too old"}
      assert conn.halted
    end

    test "returns 401 and halts when signature header is missing", %{conn: conn} do
      body = valid_body()

      conn =
        conn
        |> sign_request(body)
        |> delete_req_header("x-slack-signature")
        |> post_interaction(body)

      assert json_response(conn, 401) == %{"error" => "missing signature header"}
      assert conn.halted
    end

    test "returns 401 and halts when body differs from the signed content", %{conn: conn} do
      signed_body = valid_body()
      tampered_body = URI.encode_query(%{"payload" => Jason.encode!(%{"actions" => ["evil"]})})

      conn =
        conn
        |> sign_request(signed_body)
        |> post_interaction(tampered_body)

      assert json_response(conn, 401) == %{"error" => "invalid signature"}
      assert conn.halted
    end
  end

  describe "VerifySlackSignature plug without CacheRawBody" do
    test "returns 401 and halts when the raw body was never cached" do
      body = valid_body()

      conn =
        Plug.Test.conn(:post, "/api/slack/interactions", body)
        |> sign_request(body)
        |> PearsWeb.Plugs.VerifySlackSignature.call([])

      assert conn.status == 401
      assert conn.halted
      assert Jason.decode!(conn.resp_body) == %{"error" => "raw body not available"}
    end
  end
end
