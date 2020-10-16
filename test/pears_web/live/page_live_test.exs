defmodule PearsWeb.PageLiveTest do
  use PearsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Create your team"
    assert render(page_live) =~ "Create your team"
  end
end
