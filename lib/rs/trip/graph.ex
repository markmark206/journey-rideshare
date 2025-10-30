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
        input(:passenger_id),

        # For the purpose of this simulation, assume a 1-dimensional space, where location is a number.
        # Once the trip starts, location_driver is continuously updated by the "car's GPS."
        input(:location_driver_initial),
        input(:location_driver),
        input(:location_pickup),
        input(:location_dropoff),

        # The pre-agreed price of the trip.
        input(:price),

        # Once the driver arrived at the pickup location, waiting for the passenger to board.
        compute(
          :waiting_for_passenger_at_pickup,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:picked_up, fn x -> not provided?(x) end},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:passenger_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> not provided?(x) end}
            ]
          }),
          &driver_at_pickup_location/1
        ),

        # Once the driver arrived at the drop off location, waiting for the passenger to exit.
        compute(
          :waiting_for_passenger_at_dropoff,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:picked_up, &provided?/1},
              {:dropped_off, fn x -> not provided?(x) end}
            ]
          }),
          &driver_at_dropoff_location/1
        ),

        # Wait for the passenger for a few minutes, before giving up..
        schedule_once(
          :done_waiting_for_passenger_at_pickup_schedule,
          unblocked_when(:waiting_for_passenger_at_pickup, &true?/1),
          &in_five_minutes/1
        ),
        mutate(
          :done_waiting_for_passenger_at_pickup,
          [
            :done_waiting_for_passenger_at_pickup_schedule,
            :waiting_for_passenger_at_pickup
          ],
          &record_driver_cancelled_time_after_waiting_for_passenger_at_pickup/1,
          mutates: :driver_cancelled_time,
          update_revision_on_change: true
        ),

        # If the driver or passenger cancel, record the time.
        input(:driver_cancelled_time),
        input(:passenger_cancelled_time),

        # When the driver picks up or drops off the passenger, record the time.
        input(:picked_up),
        compute(:driver_reported_pickup_time, [:picked_up], &record_pickup_time/1),
        input(:dropped_off),
        compute(:driver_reported_dropoff_time, [:dropped_off], &record_dropoff_time/1),

        # Determine notable locations. staring point? pickup point? drop off point?
        compute(
          :current_location_label,
          [:location_driver],
          fn x ->
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
        ),
        compute(
          :en_route,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label, fn x -> x.node_value == en_route_label() end}
            ]
          }),
          fn _ -> {:ok, true} end
        ),
        compute(
          :at_starting_point,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label, fn x -> x.node_value == starting_point_label() end}
            ]
          }),
          fn _ -> {:ok, true} end
        ),
        compute(
          :reached_pickup_location,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label,
               fn x ->
                 x.node_value == pickup_point_label()
               end}
            ]
          }),
          fn _ -> {:ok, true} end
        ),
        compute(
          :reached_dropoff_location,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label,
               fn x ->
                 x.node_value == dropoff_point_label()
               end}
            ]
          }),
          fn _ -> {:ok, true} end
        ),

        # ETA for pickup.
        compute(
          :pickup_eta,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:passenger_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> not provided?(x) end}
            ]
          }),
          &update_pickup_eta/1
        ),

        # ETA for dropoff.
        compute(
          :dropoff_eta,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:passenger_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &update_dropoff_eta/1
        ),

        # Continuously polling for driver's location and updating `location_driver`.
        schedule_recurring(
          :driver_location_current_schedule,
          unblocked_when({
            :and,
            [
              {:trip_completed_at, fn x -> not provided?(x) end},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:passenger_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &in_five_seconds/1
        ),
        mutate(
          :driver_location_current_update,
          [:driver_location_current_schedule],
          &fetch_simulated_current_location/1,
          mutates: :location_driver,
          update_revision_on_change: true
        ),

        # Wait for the passenger to exit the car for a few minutes, before asking them to leave.
        schedule_once(
          :done_waiting_for_passenger_to_leave_schedule,
          unblocked_when(:waiting_for_passenger_at_dropoff, &true?/1),
          &in_five_minutes/1
        ),
        mutate(
          :done_waiting_for_passenger_to_leave,
          [:done_waiting_for_passenger_to_leave_schedule, :waiting_for_passenger_at_dropoff],
          &record_driver_asked_for_customer_to_leave/1,
          mutates: :dropped_off,
          update_revision_on_change: true
        ),

        # Once the drop off occurred, the payment is processed.
        compute(:payment, [:driver_reported_dropoff_time, :price], &process_payment/1),
        compute(
          :trip_completed_at,
          unblocked_when({
            :or,
            [
              {:driver_cancelled_time, &provided?/1},
              {:passenger_cancelled_time, &provided?/1},
              {:payment, &provided?/1}
            ]
          }),
          &now/1
        ),

        # Record the history of the trip.
        historian(
          :trip_history,
          unblocked_when({
            :or,
            [
              {:done_waiting_for_passenger_at_pickup, &provided?/1},
              {:done_waiting_for_passenger_to_leave, &provided?/1},
              {:location_driver_initial, &provided?/1},
              {:driver_cancelled_time, &provided?/1},
              {:passenger_cancelled_time, &provided?/1},
              {:picked_up, &provided?/1},
              {:dropped_off, &provided?/1},
              {:payment, &provided?/1},
              {:at_starting_point, &provided?/1},
              {:reached_pickup_location, &provided?/1},
              {:reached_dropoff_location, &provided?/1},
              {:en_route, &provided?/1},
              {:trip_completed_at, &provided?/1}
            ]
          })
        )
      ],
      f_on_save: &notify_pubsub_of_trip_update/3,
      execution_id_prefix: @graph_name
    )
  end
end
