defmodule RsWeb.Live.Home.Index do
  use RsWeb, :live_view

  import RsWeb.Live.Classes
  require Logger

  def mount(params, session, socket) do
    Logger.info("Mounting RSWeb.Live.Home.Index LiveView #{inspect(params)}")

    connected? = connected?(socket)

    socket =
      assign(socket, connected?: connected?)
      |> mount_with_connected(params, session, connected?)

    {:ok, socket}
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == true do
    Logger.info("Connected to LiveView")
    socket
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.info("Not connected to LiveView")
    socket
  end

  # TRIPA15Z60HXG5LH8EDM716X
  # http://localhost:4000/trip/TRIPA15Z60HXG5LH8EDM716X
  def render(assigns) do
    ~H"""
    <div>
      <div class="mx-auto max-w-2xl space-y-6">
        <div :if={@connected?} class="space-y-4">
          <div class={section()}>
            <h1>Home</h1>
            {live_render(@socket, RsWeb.Live.Trip.Index,
              id: "trip-lv-TRIP3ZZ9EZ842J4M9A592VXM",
              session: %{"trip" => "TRIP3ZZ9EZ842J4M9A592VXM"}
            )}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
