defmodule RsWeb.PageControllerTest do
  use RsWeb.ConnCase
  import Phoenix.LiveViewTest

  test "LIVE GET /", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Trips in progress"
  end
end
