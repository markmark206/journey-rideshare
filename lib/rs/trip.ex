defmodule RS.Trip do
  require Logger

  def new(
        driver_id,
        passenger_id,
        driver_location,
        location_pickup,
        location_dropoff,
        price \\ nil
      ) do
    price = if is_nil(price), do: (location_dropoff - location_pickup) * 20, else: price

    Logger.info("""
    Starting a new trip.

    Driver: #{driver_id}
    Current Driver Location: #{driver_location}

    Passenger: #{passenger_id}
    Pickup Location: #{location_pickup}
    Dropoff Location: #{location_dropoff}

    Price: $#{price}
    """)

    trip =
      RS.Trip.Graph.graph()
      |> Journey.start_execution()
      |> Journey.set(%{
        driver_id: driver_id,
        passenger_id: passenger_id,
        location_driver_initial: driver_location,
        location_driver: driver_location,
        location_pickup: location_pickup,
        location_dropoff: location_dropoff,
        price: price
      })

    trip.id
  end
end
