defmodule RsWeb.Live.Home.Index do
  use RsWeb, :live_view

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

    trips_in_progress =
      Journey.list_executions(
        graph_name: "trip",
        filter_by: [{:trip_completed_at, :is_nil}],
        limit: 100
      )
      |> Enum.count()
      |> IO.inspect(label: "active_trips")

    trips =
      Journey.list_executions(graph_name: "trip", sort_by: [created_at: :desc], limit: 100)
      |> Enum.map(fn execution -> execution.id end)

    # socket |> assign(trips: ["TRIPY126H95HXBE33D1DD7YB", "TRIPRV8YEEZ19J50M6H1M3ZV"])
    socket
    |> assign(trips: trips)
    |> assign(trips_in_progress: trips_in_progress)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.info("Not connected to LiveView")
    socket |> assign(trips: [])
  end

  def handle_event("start_trip", _params, socket) do
    Logger.info("Starting trip")

    driver = RS.Driver.new("Mario")
    passenger = RS.Passenger.new("Luigi")

    initial_driver_location = :rand.uniform(3) + 2
    location_pickup = initial_driver_location + :rand.uniform(5) + 3
    location_dropoff = location_pickup + :rand.uniform(14) + 5
    price = (location_dropoff - location_pickup) * 3 + (location_pickup - initial_driver_location) * 2

    trip =
      RS.Trip.new(
        driver,
        passenger,
        initial_driver_location,
        location_pickup,
        location_dropoff,
        price
      )

    trips = [trip | socket.assigns.trips]

    socket =
      socket
      |> assign(trips: trips)

    {:noreply, socket}
  end

  # TRIPA15Z60HXG5LH8EDM716X
  # http://localhost:4000/trip/TRIPA15Z60HXG5LH8EDM716X
  def render(assigns) do
    ~H"""
    <div>
      <div class="mx-auto max-w-2xl space-y-6">
        <div :if={@connected?} class="space-y-4">
          <div :if={@trips_in_progress > 0} class="text-sm font-mono border-1 rounded-md p-4 bg-base-100">
            Trips in progress: {@trips_in_progress}
          </div>
          <div class="mx-auto max-w-2xl flex justify-center px-3">
            <.button
              id="start-a-new-trip-button-id"
              disabled={@trips_in_progress >= 20}
              phx-click="start_trip"
              class="btn btn-sm btn-primary p-4 m-3 w-full"
            >
              Start a New Trip
            </.button>
          </div>

          <%= for trip <- @trips do %>
            {live_render(@socket, RsWeb.Live.Trip2.Index,
              id: "trip-lv-#{trip}",
              session: %{"trip" => trip}
            )}
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
