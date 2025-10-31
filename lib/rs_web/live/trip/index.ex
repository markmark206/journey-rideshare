defmodule RsWeb.Live.Trip.Index do
  use RsWeb, :live_view

  import RsWeb.Live.Classes
  require Logger

  def mount(params, session, socket) do
    Logger.debug("Mounting RSWeb.Live.Trip.Index LiveView #{inspect(params)}")

    connected? = connected?(socket)
    embedded? = not is_map(params)

    time_zone =
      socket
      |> get_connect_params()
      |> case do
        nil -> nil
        params -> Map.get(params, "time_zone")
      end

    show_details = is_map(params) and false != Map.get(params, "show_details", false)

    socket =
      assign(socket, connected?: connected?)
      |> assign(show_details: show_details)
      |> assign(embedded?: embedded?)
      |> assign(time_zone: time_zone)
      |> mount_with_connected(params, session, connected?)

    {:ok, socket}
  end

  def mount_with_connected(socket, params, session, connected?) when connected? == true do
    Logger.debug("Connected to LiveView")

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

    if trip != nil do
      :ok = Phoenix.PubSub.subscribe(Rs.PubSub, "trip:#{trip}")
    end

    socket |> load_trip_to_socket_assigns(trip)
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.debug("Not connected to LiveView")
    socket
  end

  def handle_event("on_pickup_customer_button_click", _params, socket) do
    trip = socket.assigns.trip

    Logger.info("#{trip}: on_pickup_customer_button_click")

    Task.start(fn ->
      Journey.set(trip, :picked_up, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :picked_up, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("on_dropoff_customer_button_click", _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: on_dropoff_customer_button_click")

    Task.start(fn ->
      Journey.set(trip, :dropped_off, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :dropped_off, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_info({:trip_updated, trip, node_name}, socket) do
    Logger.debug("#{trip}: Handling trip update #{node_name}")
    {:noreply, load_trip_to_socket_assigns(socket, trip)}
  end

  def load_trip_to_socket_assigns(socket, trip) when trip == nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")

    socket
    |> assign(:driver, nil)
    |> assign(:order_id, nil)
    |> assign(:trip, nil)
    |> assign(:trip_values, nil)
  end

  def load_trip_to_socket_assigns(socket, trip) when trip != nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")
    trip_values = Journey.load(trip) |> Journey.values(include_unset_as_nil: true)

    socket
    |> assign(:driver, trip_values.driver_id)
    |> assign(:order_id, trip_values.order_id)
    |> assign(:trip, trip)
    |> assign(:trip_values, trip_values)
  end

  defp to_datetime_string(unix_timestamp, time_zone) do
    unix_timestamp
    |> DateTime.from_unix!()
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%Y%m%d %H:%M:%S")
  end
end
