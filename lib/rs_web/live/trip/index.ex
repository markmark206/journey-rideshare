defmodule RSWeb.Live.Trip.Index do
  use RsWeb, :live_view

  require Logger

  def mount(_params, _session, socket) do
    Logger.info("Mounting Trip.Index LiveView")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Trips</h1>
    </div>
    """
  end
end
