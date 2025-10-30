defmodule RsWeb.Live.Home.Index do
  use RsWeb, :live_view

  require Logger

  def mount(params, session, socket) do
    connected? = connected?(socket)

    time_zone =
      socket
      |> get_connect_params()
      |> case do
        nil -> nil
        params -> Map.get(params, "time_zone")
      end

    socket =
      assign(socket, connected?: connected?)
      |> assign(time_zone: time_zone)
      |> mount_with_connected(params, session, connected?)

    {:ok, socket}
  end

  defp load_trips(socket) do
    Logger.debug("Loading trips")

    all_trips =
      Journey.list_executions(graph_name: "trip", sort_by: [created_at: :desc], limit: 100)

    trips_in_progress =
      all_trips
      |> Enum.count(fn execution ->
        execution
        |> Map.get(:values)
        |> Enum.find(fn v ->
          v.node_name == :trip_completed_at
        end)
        |> Map.get(:set_time)
        |> is_nil()
      end)

    trips =
      all_trips
      |> Enum.map(fn execution -> execution.id end)

    socket
    |> assign(trips: trips)
    |> assign(trips_in_progress: trips_in_progress)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == true do
    Logger.debug("Connected to LiveView")
    :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "new_trips")
    :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "trip_completed")

    load_trips(socket)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.debug("Not connected to LiveView")
    socket |> assign(trips: [])
  end

  def handle_event("on_start_trip_button_click", _params, socket) do
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

    :ok = Phoenix.PubSub.broadcast(Rs.PubSub, "new_trips", {:trip_created, trip})

    {:noreply, socket}
  end

  def handle_info({:trip_created, trip}, socket) do
    Logger.debug("#{trip}: Handling trip creation")
    total_trips = socket.assigns.trips_in_progress + 1

    trips = if socket.assigns.trips |> Enum.member?(trip), do: socket.assigns.trips, else: [trip | socket.assigns.trips]

    socket =
      socket
      |> assign(trips_in_progress: total_trips)
      |> assign(trips: trips)

    {:noreply, socket}
  end

  def handle_info({:trip_completed, trip}, socket) do
    Logger.debug("#{trip}: Handling trip completion")
    total_trips = socket.assigns.trips_in_progress - 1

    trips = if trip in socket.assigns.trips, do: socket.assigns.trips, else: [trip | socket.assigns.trips]

    socket =
      socket
      |> assign(trips_in_progress: total_trips)
      |> assign(trips: trips)

    {:noreply, socket}
  end

  def drivers_available(), do: 5

  # TRIPA15Z60HXG5LH8EDM716X
  # http://localhost:4000/trip/TRIPA15Z60HXG5LH8EDM716X
  def render(assigns) do
    ~H"""
    <div>
      <div class="mx-auto max-w-2xl space-y-6">
        <div :if={@connected?} class="space-y-4">
          <div class="mx-auto max-w-2xl flex justify-center px-3">
            <div class="text-sm font-mono border-1 rounded-md mt-3 p-4 bg-base-100 w-full">
              Trips in progress: <span class="font-mono badge badge-neutral">{@trips_in_progress}</span>
            </div>
          </div>

          <div class="mx-auto max-w-2xl flex justify-center px-3">
            <.button
              id="start-a-new-trip-button-id"
              disabled={@trips_in_progress >= drivers_available()}
              phx-click="on_start_trip_button_click"
              class="btn btn-sm btn-primary p-4 m-3 w-full"
            >
              Start a New Trip
              <span
                :if={@trips_in_progress >= drivers_available()}
                class=""
              >
                (no drivers available)
              </span>
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
