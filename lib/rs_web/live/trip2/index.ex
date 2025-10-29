defmodule RsWeb.Live.Trip2.Index do
  use RsWeb, :live_view

  import RsWeb.Live.Classes
  require Logger

  def mount(params, session, socket) do
    Logger.info("Mounting RSWeb.Live.Trip.Index LiveView #{inspect(params)}")

    connected? = connected?(socket)
    embedded? = not is_map(params)

    show_details = is_map(params) and false != Map.get(params, "show_details", false)

    socket =
      assign(socket, connected?: connected?)
      |> assign(show_details: show_details)
      |> assign(embedded?: embedded?)
      |> mount_with_connected(params, session, connected?)

    {:ok, socket}
  end

  def mount_with_connected(socket, params, session, connected?) when connected? == true do
    Logger.info("Connected to LiveView")

    trip =
      if session["trip"] != nil do
        session["trip"]
      else
        if is_map(params) do
          Map.get(params, "trip")
        else
          nil
        end
      end

    # params["trip"] |> IO.inspect(label: "trip")
    # trip = nil

    if trip != nil do
      :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "trip:#{trip}")
    end

    socket |> load_trip_to_socket_assigns(trip)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.info("Not connected to LiveView")
    socket
  end

  # def handle_params(_params, _url, socket) do
  #  {:noreply, socket}
  # end

  def handle_event("pickup_customer", _params, socket) do
    Logger.info("Picking up customer")

    trip = socket.assigns.trip

    Task.start(fn ->
      Journey.set(trip, :picked_up, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :picked_up, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("dropoff_customer", _params, socket) do
    Logger.info("dropping off customer")

    trip = socket.assigns.trip

    Task.start(fn ->
      Journey.set(trip, :dropped_off, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :dropped_off, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("start_trip", _params, socket) do
    Logger.info("Starting trip")

    driver = RS.Driver.new("Mario")
    passenger = RS.Passenger.new("Luigi")

    socket =
      socket
      |> assign(:driver, driver)
      |> assign(:passenger, passenger)

    initial_driver_location = :rand.uniform(5) + 2
    location_pickup = initial_driver_location + :rand.uniform(5) + 3
    location_dropoff = location_pickup + :rand.uniform(20) + 5
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

    if socket.assigns.trip != nil do
      :ok = Phoenix.PubSub.unsubscribe(Rs.PubSub, "trip:#{socket.assigns.trip}")
    end

    :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "trip:#{trip}")

    socket =
      socket
      |> load_trip_to_socket_assigns(trip)
      |> push_patch(to: "/trip/#{trip}")

    {:noreply, socket}
  end

  def handle_info({:trip_updated, trip}, socket) do
    Logger.info("#{trip}: Handling trip update")
    {:noreply, load_trip_to_socket_assigns(socket, trip)}
  end

  def load_trip_to_socket_assigns(socket, trip) when trip == nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")

    socket
    |> assign(:driver, nil)
    |> assign(:passenger, nil)
    |> assign(:trip, nil)
    |> assign(:trip_values, nil)
    |> assign(:trip_summary, nil)
  end

  def load_trip_to_socket_assigns(socket, trip) when trip != nil do
    Logger.info("#{trip}: Loading trip to socket assigns")
    trip_values = Journey.load(trip) |> Journey.values(include_unset_as_nil: true)
    # Journey.Tools.summarize_as_text(trip)
    trip_summary = nil

    # history =
    #  trip_values.trip_history |> Enum.map(fn %{"node" => node} -> "#{node}" end) |> Enum.join("\n")

    # IO.inspect(history, label: "history")

    socket
    |> assign(:driver, trip_values.driver_id)
    |> assign(:passenger, trip_values.passenger_id)
    |> assign(:trip, trip)
    |> assign(:trip_values, trip_values)
    |> assign(:trip_summary, trip_summary)
  end

  # def render(assigns) do
  #  ~H"""
  #  """
  # end
end
