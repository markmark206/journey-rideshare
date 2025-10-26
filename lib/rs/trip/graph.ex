defmodule RS.Trip.Graph do
  import Journey.Node
  import Journey.Node.Conditions
  import Journey.Node.UpstreamDependencies

  import RS.Trip.Logic

  require Logger

  @graph_name "trip"

  def graph() do
    Journey.new_graph(
      @graph_name,
      "v1.0",
      [
        compute(:created_at, [], &now/1),

        # Initial parameters of the trip.
        input(:driver_id),
        input(:customer_id),

        # For the purpose of this simulation, assume a 1-dimensional space, where location is a number.
        input(:pickup_location),
        input(:dropoff_location),

        # The pre-agreed price of the trip.
        input(:price),

        # Current driver location, continuously read from the car's GPS.
        input(:driver_location_current),

        # If the driver or customer cancel, record the time.
        input(:driver_cancelled_time),
        input(:customer_cancelled_time),

        # When the driver picks up or drops off the customer, report the time.
        input(:driver_reported_pickup_time),
        input(:driver_reported_dropoff_time),

        # Periodically recomputing Pickup ETA
        schedule_recurring(
          :pickup_eta_schedule,
          unblocked_when({
            :and,
            [
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:customer_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> not provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &in_five_seconds/1
        ),
        compute(
          :pickup_eta,
          unblocked_when({
            :and,
            [
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:customer_cancelled_time, fn x -> not provided?(x) end},
              {:pickup_eta_schedule, &provided?/1},
              {:driver_reported_pickup_time, fn x -> not provided?(x) end}
            ]
          }),
          &update_pickup_eta/1
        ),

        # Periodically recomputing Dropoff ETA
        schedule_recurring(
          :dropoff_eta_schedule,
          unblocked_when({
            :and,
            [
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:customer_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, &provided?/1},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &in_five_seconds/1
        ),
        compute(
          :dropoff_eta,
          unblocked_when({
            :and,
            [
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:customer_cancelled_time, fn x -> not provided?(x) end},
              {:dropoff_eta_schedule, &provided?/1},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &update_dropoff_eta/1
        ),

        # Periodically polling for driver's location.
        schedule_recurring(
          :driver_location_current_schedule,
          unblocked_when({
            :and,
            [
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:customer_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &in_five_seconds/1
        ),
        mutate(
          :driver_location_current_update,
          [:driver_location_current_schedule],
          &fetch_simulated_current_location/1,
          mutates: :driver_location_current
        ),

        # Once the drop off occurred, the payment is processed.
        compute(:payment, [:driver_reported_dropoff_time, :price], &process_payment/1)
      ],
      execution_id_prefix: @graph_name
    )
  end
end
