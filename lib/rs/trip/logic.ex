defmodule RS.Trip.Logic do
  require Logger

  def in_five_seconds(_) do
    {:ok, System.system_time(:second) + 5}
  end

  def ask_navigation_subsystem_for_eta(location1, location2) do
    abs(location2 - location1)
  end

  def read_gps_data(last_position) do
    last_position + 1
  end

  def update_pickup_eta(%{
        driver_location_current: driver_location_current,
        pickup_location: pickup_location
      })
      when driver_location_current != pickup_location do
    eta = ask_navigation_subsystem_for_eta(driver_location_current, pickup_location)

    Logger.info(
      "driving to pickup location (#{pickup_location}). pickup ETA: #{eta}. current location: #{driver_location_current}"
    )

    {:ok, eta}
  end

  def update_pickup_eta(%{pickup_location: pickup_location}) do
    Logger.info("waiting for the customer at the pickup location (#{pickup_location}).")

    {:ok, 0}
  end

  def update_dropoff_eta(%{
        driver_location_current: driver_location_current,
        dropoff_location: dropoff_location
      })
      when driver_location_current != dropoff_location do
    eta = ask_navigation_subsystem_for_eta(driver_location_current, dropoff_location)

    Logger.info(
      "transporting passenger to drop off location (#{dropoff_location}). drop off ETA: #{eta} (current location: #{driver_location_current})"
    )

    {:ok, eta}
  end

  def update_dropoff_eta(%{dropoff_location: dropoff_location}) do
    Logger.info(
      "waiting for the customer to exit the vehicle at the drop off location (#{dropoff_location})."
    )

    {:ok, 0}
  end

  def fetch_simulated_current_location(%{driver_reported_pickup_time: _} = values) do
    # The customer has been picked up, so we are driving to the drop off location.
    last_position = Map.get(values, :driver_location_current)

    new_position =
      if last_position == values.dropoff_location do
        # We have arrived, don't go anywhere.
        last_position
      else
        read_gps_data(last_position)
      end

    {:ok, new_position}
  end

  def fetch_simulated_current_location(values) do
    # The customer has not been picked up, so we are driving to the pickup location.
    last_position = Map.get(values, :driver_location_current)

    new_position =
      if last_position == values.pickup_location do
        # We have arrived, don't go anywhere.
        last_position
      else
        read_gps_data(last_position)
      end

    {:ok, new_position}
  end

  def process_payment(%{customer_id: customer_id, driver_id: driver_id, price: price}) do
    Logger.info(
      "customer dropped off. charging customer `#{customer_id}` #{price}, to driver `#{driver_id}`"
    )

    {:ok, "charged"}
  end

  def now(_) do
    {:ok, System.system_time(:second)}
  end
end
