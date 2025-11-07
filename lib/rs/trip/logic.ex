defmodule RS.Trip.Logic do
  @moduledoc false
  require Logger

  def en_route?(x) do
    x.node_value == en_route_label()
  end

  def at_starting_point?(x) do
    x.node_value == starting_point_label()
  end

  def at_drop_off?(x) do
    x.node_value == dropoff_point_label()
  end

  def at_pick_up?(x) do
    x.node_value == pickup_point_label()
  end

  def starting_point_label(), do: "starting point"
  def pickup_point_label(), do: "pickup point"
  def dropoff_point_label(), do: "drop off point"
  def en_route_label(), do: "en route"

  def in_five_seconds(_) do
    {:ok, System.system_time(:second) + 5}
  end

  def in_a_minute(_) do
    {:ok, System.system_time(:second) + 1 * 60}
  end

  def ask_navigation_subsystem_for_eta(location1, location2) do
    abs(location2 - location1)
  end

  def read_gps_data(last_position) do
    last_position + 1
  end

  def log_driving_to_pickup(%{
        location_driver: location_driver,
        location_pickup: location_pickup,
        execution_id: execution_id
      })
      when location_driver != location_pickup do
    eta = ask_navigation_subsystem_for_eta(location_driver, location_pickup)

    Logger.info(
      "#{execution_id}: Driving to pickup location #{location_pickup}. Currently at: #{location_driver}. ETA: in #{eta}."
    )

    {:ok, eta}
  end

  def log_driving_to_pickup(%{location_pickup: location_pickup, execution_id: execution_id}) do
    Logger.info("#{execution_id}: Waiting at pickup location #{location_pickup}.")
    {:ok, 0}
  end

  def log_driving_to_dropoff(%{
        location_driver: location_driver,
        location_dropoff: location_dropoff,
        execution_id: execution_id
      })
      when location_driver != location_dropoff do
    eta = ask_navigation_subsystem_for_eta(location_driver, location_dropoff)

    Logger.info(
      "#{execution_id}: Driving item to drop off location #{location_dropoff}. Currently at #{location_driver}. ETA: in #{eta}."
    )

    {:ok, eta}
  end

  def log_driving_to_dropoff(%{location_dropoff: location_dropoff, execution_id: execution_id}) do
    Logger.info(
      "#{execution_id}: Waiting for the customer to come pick up the item at the drop off location #{location_dropoff}."
    )

    {:ok, 0}
  end

  def fetch_simulated_current_location(%{picked_up: true} = values) do
    # The item has been picked up, so we are driving to the drop off location.
    last_position = Map.get(values, :location_driver)

    new_position =
      if last_position == values.location_dropoff do
        # We have arrived, don't go anywhere.
        last_position
      else
        read_gps_data(last_position)
      end

    {:ok, new_position}
  end

  def fetch_simulated_current_location(values) do
    # The item has not been picked up, so we are driving to the pickup location.
    last_position = Map.get(values, :location_driver)

    new_position =
      if last_position == values.location_pickup do
        # We have arrived, don't go anywhere.
        last_position
      else
        read_gps_data(last_position)
      end

    {:ok, new_position}
  end

  def compute_location_label(x) do
    location_label =
      cond do
        Map.get(x, :location_driver_initial) == x.location_driver ->
          starting_point_label()

        Map.get(x, :location_pickup) == x.location_driver ->
          pickup_point_label()

        Map.get(x, :location_dropoff) == x.location_driver ->
          dropoff_point_label()

        true ->
          en_route_label()
      end

    {:ok, location_label}
  end

  def process_payment(%{order_id: order_id, driver_id: driver_id, price_cents: price_cents, execution_id: execution_id}) do
    Logger.info("""
    #{execution_id}:
    Item dropped off.
    Charging `#{order_id}` $#{price_cents / 100}, to driver `#{driver_id}`.
    The trip is now complete.
    """)

    {:ok, "charged $#{price_cents / 100}. pickup `#{order_id}`, driver `#{driver_id}`"}
  end

  def now(_) do
    {:ok, System.system_time(:second)}
  end

  def set_driver_cancelled(%{execution_id: execution_id}) do
    Logger.info("#{execution_id}: Driver cancelled after waiting for pickup item to become available.")
    {:ok, true}
  end

  def is_driver_at_restaurant(%{
        location_driver: location_driver,
        location_pickup: location_pickup,
        execution_id: execution_id
      }) do
    if location_driver == location_pickup do
      Logger.info("#{execution_id}: Driver is at pickup location #{location_pickup}")
      {:ok, true}
    else
      {:ok, false}
    end
  end

  def driver_at_dropoff_location(%{
        location_driver: location_driver,
        location_dropoff: location_dropoff,
        execution_id: execution_id
      }) do
    if location_driver == location_dropoff do
      Logger.info("#{execution_id}: Driver is at dropoff location #{location_dropoff}")
      {:ok, true}
    else
      {:ok, false}
    end
  end

  def notify_pubsub_of_trip_update(trip, node_name, _values) do
    Logger.debug("#{trip}: Notifying pubsub of trip update #{node_name}")
    Phoenix.PubSub.broadcast(Rs.PubSub, "trip:#{trip}", {:trip_updated, trip, node_name})
    {:ok, "trip updated"}
  end
end
