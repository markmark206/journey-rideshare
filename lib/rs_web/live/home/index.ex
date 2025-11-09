defmodule RsWeb.Live.Home.Index do
  @moduledoc false
  use RsWeb, :live_view

  require Logger

  @delivery_items [
    "🍔",
    "🍕",
    "🍟",
    "🍣",
    "🍜",
    "🌮",
    "🍓",
    "🍒",
    "🍇",
    "🍎",
    "🍊",
    "🍋",
    "🍌",
    "🍐",
    "🍑",
    "🍆",
    "🥑",
    "🥦",
    "🥬",
    "🥕",
    "🌿",
    "🍅",
    "🍉",
    "🍝",
    "🌯",
    "🥪",
    "🍛",
    "🧆",
    "🍲"
  ]

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
      assign(socket, :connected?, connected?)
      |> assign(:item_to_deliver, Enum.random(@delivery_items))
      |> assign(:time_zone, time_zone)
      |> assign(:view_analytics, false)
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

    graph = RS.Trip.Graph.graph()

    analytics_text =
      Journey.Insights.FlowAnalytics.flow_analytics(graph.name, graph.version)
      |> Journey.Insights.FlowAnalytics.to_text()

    socket
    |> assign(trips: trips)
    |> assign(trips_in_progress: trips_in_progress)
    |> assign(:analytics, analytics_text)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == true do
    Logger.debug("Connected to LiveView")
    :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "new_trips")
    :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "trip_completed")

    socket
    |> load_trips()
    |> assign(:newly_created_trip_id, nil)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.debug("Not connected to LiveView")

    socket
    |> assign(trips: [])
    |> assign(:analytics, "")
    |> assign(:newly_created_trip_id, nil)
  end

  def handle_event("on-toggle-view-analytics-click" = event, _params, socket) do
    Logger.info(event)

    socket =
      socket
      |> assign(:view_analytics, not socket.assigns.view_analytics)

    {:noreply, socket}
  end

  def handle_event("on_start_trip_button_click", _params, socket) do
    Logger.info("Starting trip")

    driver_id = RS.Helpers.random_string("DRIVER", 15)
    order_id = RS.Helpers.random_string("ORDER", 15)

    initial_driver_location = 0
    location_pickup = initial_driver_location + :rand.uniform(2) + 2
    location_dropoff = location_pickup + :rand.uniform(10) + 4

    price_cents =
      (300 + (location_dropoff - location_pickup) * 100 / 3 + (location_pickup - initial_driver_location) * 100 / 2)
      |> Float.round()

    trip =
      RS.Trip.new(
        driver_id,
        order_id,
        initial_driver_location,
        location_pickup,
        location_dropoff,
        price_cents,
        socket.assigns.item_to_deliver,
        socket.assigns.time_zone
      )

    :ok = Phoenix.PubSub.broadcast(Rs.PubSub, "new_trips", {:trip_created, trip})

    socket =
      socket
      |> assign(:item_to_deliver, Enum.random(@delivery_items))
      |> assign(:newly_created_trip_id, trip)

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

  def terminate(reason, _socket) do
    Logger.info("Terminating Live.Home (reason: #{inspect(reason)})")
    :ok
  end

  def drivers_available(), do: 5

  def render(assigns) do
    ~H"""
    <div>
      <div class="mx-auto max-w-2xl space-y-6">
        <div :if={@connected?} class="space-y-4">
          <div class="mx-auto max-w-2xl flex justify-center px-3">
            <div class="text-sm font-mono border-1 rounded-md mt-3 p-4 bg-base-100 w-full">
              Trips in progress: <span class="font-mono badge badge-neutral">{@trips_in_progress}</span>
              <div class="pt-2">
                <div
                  id="form-show-analytics-id"
                  phx-click="on-toggle-view-analytics-click"
                  class="hover:bg-info p-2 rounded-md"
                >
                  <.icon
                    :if={not @view_analytics}
                    name="hero-chevron-down"
                    class="w-4 h-4 p-1 "
                  />
                  <.icon
                    :if={@view_analytics}
                    name="hero-chevron-up"
                    class="w-4 h-4 p-1"
                  /> View Analytics
                </div>
              </div>

              <pre
                :if={@view_analytics}
                id="analytics-id"
                class="border-1 p-3 bg-neutral rounded-md my-2 whitespace-pre-wrap break-words"
              >{@analytics}</pre>
            </div>
          </div>

          <div id="about-service-id" class="mx-auto max-w-2xl flex justify-center px-3">
            <div class="text-sm justify-center font-mono border-1 rounded-md mt-3 p-4 bg-base-100 w-full">
              <div class="py-1">
                This is a dashboard for the play-demo JourDash Delivery service.
              </div>
              <div class="py-1">
                The service is built with
                <a
                  class="link link-primary"
                  target="_blank"
                  href="https://elixir-lang.org/"
                >
                  Elixir
                </a>
                and <a
                  class="link link-primary"
                  target="_blank"
                  href="https://www.phoenixframework.org/"
                >Phoenix LiveView</a>, with
                <a class="link link-primary" target="_blank" href="https://hexdocs.pm/journey/">Journey</a>
                providing persistence, scheduling, crash recovery, and orchestration.
              </div>
              <div class="py-1">
                JourDash source is available on Github:
                <a
                  class="link link-primary"
                  target="_blank"
                  href="https://github.com/markmark206/journey-food-delivery"
                >
                  repo
                </a>
                |
                <a
                  class="link link-primary"
                  target="_blank"
                  href="https://github.com/markmark206/journey-food-delivery/blob/main/lib/rs/trip/graph.ex"
                >
                  graph
                </a>
              </div>
              <div class="py-1">
                Let's deliver some snacks! <span class="text-lg animate-pulse">{@item_to_deliver}</span>
              </div>
            </div>
          </div>

          <% driver_available? = @trips_in_progress < drivers_available() %>

          <div class="mx-auto max-w-2xl flex justify-center px-3">
            <.button
              id="start-a-new-trip-button-id"
              disabled={not driver_available?}
              phx-click="on_start_trip_button_click"
              class="btn btn-sm btn-primary p-4 m-3 w-full"
            >
              <span class="">
                <span class={["text-lg p-2", driver_available? && "animate-pulse"]}>{@item_to_deliver}</span>
                Start a New Delivery
                <span class={["text-lg p-2", driver_available? && "animate-pulse"]}>{@item_to_deliver}</span>
              </span>
              <span
                :if={not driver_available?}
                class=""
              >
                (no drivers available)
              </span>
            </.button>
          </div>

          <div :if={@newly_created_trip_id != nil} class="hidden mx-auto max-w-2xl px-3">
            <div class="text-sm font-mono border-1 rounded-md p-3 bg-base-100">
              New Trip Created: <span id="new-trip-created-id">{@newly_created_trip_id}</span>
            </div>
          </div>

          <%= for trip <- @trips do %>
            <div class={if trip == @newly_created_trip_id, do: "border-l-3 border-info", else: ""}>
              {live_render(@socket, RsWeb.Live.Trip.Index,
                id: "trip-lv-#{trip}",
                session: %{"trip" => trip}
              )}
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
