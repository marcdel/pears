defmodule PearsWeb.SlackInteractionControllerTest do
  use PearsWeb.ConnCase, async: true

  describe "POST /slack/interactions" do
    test "returns 200 when successfully decodes payload", %{conn: conn} do
      body = %{"payload" => Jason.encode!(%{"actions" => []})}

      conn = post(conn, Routes.slack_interaction_path(conn, :create), body)

      assert json_response(conn, 200)
    end

    test "returns 400 when unsuccessfully decodes payload", %{conn: conn} do
      body = %{"payload" => ""}

      conn = post(conn, Routes.slack_interaction_path(conn, :create), body)

      assert json_response(conn, 400)
    end
  end
end
