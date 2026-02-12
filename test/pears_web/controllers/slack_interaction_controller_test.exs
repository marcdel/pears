defmodule PearsWeb.SlackInteractionControllerTest do
  use PearsWeb.ConnCase, async: true

  defp sign_request(conn, body) do
    timestamp = System.system_time(:second) |> to_string()
    secret = Application.fetch_env!(:pears, :slack_signing_secret)
    basestring = "v0:#{timestamp}:#{body}"

    signature =
      :crypto.mac(:hmac, :sha256, secret, basestring)
      |> Base.encode16(case: :lower)

    conn
    |> put_req_header("x-slack-request-timestamp", timestamp)
    |> put_req_header("x-slack-signature", "v0=#{signature}")
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
end
