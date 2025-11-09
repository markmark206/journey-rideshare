defmodule RsWeb.Live.Trip.Index do
  @moduledoc false
  use RsWeb, :live_view

  require Logger

  def mount(params, session, socket) do
    Logger.debug("Mounting RSWeb.Live.Trip.Index LiveView #{inspect(params)}")

    connected? = connected?(socket)
    embedded? = not is_map(params)
    expanded? = not embedded?

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
      |> assign(:expanded?, expanded?)
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

    socket
    |> load_trip_to_socket_assigns(trip)
    |> start_refresh_timer_maybe()
  end

  def mount_with_connected(socket, _params, _session, connected?) when connected? == false do
    Logger.debug("Not connected to LiveView")

    socket
    |> assign(:refresh_timer_ref, nil)
  end

  def handle_event("on_trip_card_chevron_down_click", _params, socket) do
    Logger.info("on_trip_card_chevron_down_click")
    socket = assign(socket, :expanded?, not socket.assigns.expanded?)
    {:noreply, socket}
  end

  def handle_event("on_pickup_item_button_click", _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: on_pickup_item_button_click")

    Task.start(fn ->
      Journey.set(trip, :picked_up, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :picked_up, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_event("on_handoff_item_button_click", _params, socket) do
    trip = socket.assigns.trip
    Logger.info("#{trip}: on_handoff_item_button_click")

    Task.start(fn ->
      Journey.set(trip, :handed_off, true)
    end)

    update_values = Map.put(socket.assigns.trip_values, :handed_off, true)
    socket = assign(socket, :trip_values, update_values)

    {:noreply, socket}
  end

  def handle_info({:trip_updated, trip, node_name}, socket) do
    Logger.debug("#{trip}: Handling trip update #{node_name}")
    {:noreply, load_trip_to_socket_assigns(socket, trip)}
  end

  def handle_info(:refresh_last_updated, socket) do
    Logger.debug("[#{socket.assigns.trip}]: :refresh_last_updated")

    socket =
      socket
      |> assign(:last_updated_seconds_ago, System.system_time(:second) - socket.assigns.trip_values.last_updated_at)
      |> start_refresh_timer_maybe()

    {:noreply, socket}
  end

  def terminate(reason, socket) do
    trip = socket.assigns[:trip]
    timer_ref = socket.assigns.refresh_timer_ref

    if timer_ref != nil do
      Process.cancel_timer(timer_ref)
      Logger.debug("#{trip}: Terminating LiveView (reason: #{inspect(reason)}), cancelled refresh timer")
    else
      Logger.debug("#{trip}: Terminating LiveView (reason: #{inspect(reason)})")
    end

    :ok
  end

  def load_trip_to_socket_assigns(socket, trip) when trip == nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")

    socket
    |> assign(:driver, nil)
    |> assign(:order_id, nil)
    |> assign(:trip, nil)
    |> assign(:trip_values, nil)
    |> assign(:last_updated_seconds_ago, 0)
    |> assign(:refresh_timer_ref, nil)
  end

  def load_trip_to_socket_assigns(socket, trip) when trip != nil do
    Logger.debug("#{trip}: Loading trip to socket assigns")
    trip_values = Journey.load(trip) |> Journey.values(include_unset_as_nil: true)
    last_updated_seconds_ago = System.system_time(:second) - trip_values.last_updated_at

    socket
    |> assign(:driver, trip_values.driver_id)
    |> assign(:order_id, trip_values.order_id)
    |> assign(:trip, trip)
    |> assign(:trip_values, trip_values)
    |> assign(:last_updated_seconds_ago, last_updated_seconds_ago)
  end

  # Start the refresh timer if a trip exists (called once on mount)
  defp start_refresh_timer_maybe(socket) do
    seconds_since_last_updated = System.system_time(:second) - socket.assigns.trip_values.last_updated_at

    timer_ref =
      seconds_since_last_updated
      |> calculate_refresh_interval()
      |> case do
        :stop ->
          Logger.debug("[#{socket.assigns.trip}]: stopping refresh timer")
          nil

        interval_ms ->
          Logger.debug("[#{socket.assigns.trip}]: Scheduling refresh timer for #{interval_ms}ms")
          Process.send_after(self(), :refresh_last_updated, interval_ms)
      end

    assign(socket, :refresh_timer_ref, timer_ref)
  end

  # Calculate progressive refresh interval based on how old the trip is
  defp calculate_refresh_interval(seconds_ago) do
    cond do
      seconds_ago < 60 -> :timer.seconds(5)
      seconds_ago < 3_600 -> :timer.minutes(1)
      seconds_ago < 86_400 -> :timer.minutes(10)
      true -> :stop
    end
  end
end
