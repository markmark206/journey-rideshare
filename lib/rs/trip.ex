defmodule RS.Trip do
  require Logger

  def new(
        driver_id,
        order_id,
        driver_location,
        location_pickup,
        location_dropoff,
        price_cents,
        pickup_item
      ) do
    Logger.info("""
    Starting a new trip.

    Driver: #{driver_id}
    Current Driver Location: #{driver_location}

    Order: #{order_id}
    Pickup Location: #{location_pickup}
    Dropoff Location: #{location_dropoff}

    Price: $#{price_cents / 100}
    Item: #{pickup_item}
    """)

    trip =
      RS.Trip.Graph.graph()
      |> Journey.start_execution()
      |> Journey.set(%{
        driver_id: driver_id,
        order_id: order_id,
        location_driver_initial: driver_location,
        location_driver: driver_location,
        location_pickup: location_pickup,
        location_dropoff: location_dropoff,
        price_cents: price_cents,
        pickup_item: pickup_item
      })

    trip.id
  end
end
