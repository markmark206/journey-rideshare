defmodule RS.Trip do
  require Logger

  def new(
        driver_id,
        customer_id,
        driver_location,
        pickup_location,
        dropoff_location,
        price \\ nil
      ) do
    price = if is_nil(price), do: (dropoff_location - pickup_location) * 20, else: price

    Logger.info("""
    Starting a new trip.

    Driver: #{driver_id}
    Current Driver Location: #{driver_location}

    Customer: #{customer_id}
    Pickup Location: #{pickup_location}
    Dropoff Location: #{dropoff_location}

    Price: $#{price}
    """)

    trip =
      RS.Trip.Graph.graph()
      |> Journey.start_execution()
      |> Journey.set(%{
        driver_id: driver_id,
        customer_id: customer_id,
        driver_location_current: driver_location,
        pickup_location: pickup_location,
        dropoff_location: dropoff_location,
        price: price
      })

    trip.id
  end
end
