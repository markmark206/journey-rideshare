defmodule RS.Trip.Logic do
  require Logger

  def starting_point_label(), do: "starting point"
  def pickup_point_label(), do: "pickup point"
  def dropoff_point_label(), do: "drop off point"
  def en_route_label(), do: "en route"

  def in_five_seconds(_) do
    {:ok, System.system_time(:second) + 5}
  end

  def in_five_minutes(_) do
    {:ok, System.system_time(:second) + 1 * 60}
  end

  def ask_navigation_subsystem_for_eta(location1, location2) do
    abs(location2 - location1)
  end

  def read_gps_data(last_position) do
    last_position + 1
  end

  def update_pickup_eta(%{
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

  def update_pickup_eta(%{location_pickup: location_pickup, execution_id: execution_id}) do
    Logger.info("#{execution_id}: Waiting at pickup location #{location_pickup}.")
    {:ok, 0}
  end

  def update_dropoff_eta(%{
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

  def update_dropoff_eta(%{location_dropoff: location_dropoff, execution_id: execution_id}) do
    Logger.info(
      "#{execution_id}: Waiting for the customer to come pick up the item at the drop off location #{location_dropoff}."
    )

    {:ok, 0}
  end

  def fetch_simulated_current_location(%{driver_reported_pickup_time: _} = values) do
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

  def compute_label(x) do
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

  def process_payment(%{passenger_id: passenger_id, driver_id: driver_id, price: price, execution_id: execution_id}) do
    Logger.info("""
    #{execution_id}:
    Item dropped off.
    Charging `#{passenger_id}` $#{price}, to driver `#{driver_id}`.
    The trip is now complete.
    """)

    {:ok, "charged $#{price}. pickup `#{passenger_id}`, driver `#{driver_id}`"}
  end

  def now(_) do
    {:ok, System.system_time(:second)}
  end

  def record_pickup_time(%{execution_id: execution_id}) do
    Logger.info("#{execution_id}: Driver picked up the item, at #{inspect(DateTime.now!("America/Los_Angeles"))}.")
    {:ok, System.system_time(:second)}
  end

  def record_dropoff_time(%{execution_id: execution_id}) do
    Logger.info(
      "#{execution_id}: Driver handed the item off to the customer, at #{inspect(DateTime.now!("America/Los_Angeles"))}."
    )

    {:ok, System.system_time(:second)}
  end

  def record_driver_cancelled_time_after_waiting_for_food_at_restaurant(%{execution_id: execution_id}) do
    Logger.info(
      "#{execution_id}: Driver cancelled the trip after waiting for pickup item to become available, at #{inspect(DateTime.now!("America/Los_Angeles"))}."
    )

    {:ok, System.system_time(:second)}
  end

  def record_driver_asked_for_customer_to_leave(%{execution_id: execution_id}) do
    Logger.info(
      "#{execution_id}: The customer didn't come out, the driver dropped off the item, at #{inspect(DateTime.now!("America/Los_Angeles"))}."
    )

    {:ok, true}
  end

  def driver_at_restaurant(%{
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
