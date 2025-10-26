defmodule RsWeb.PageController do
  use RsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
