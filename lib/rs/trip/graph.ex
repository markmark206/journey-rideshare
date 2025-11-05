defmodule RS.Trip.Graph do
  @moduledoc false
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
        input(:order_id),

        # For the purpose of this simulation, assume a 1-dimensional space, where location is a number.
        # Once the trip starts, location_driver is continuously updated by the "car's GPS."
        input(:location_driver_initial),
        input(:location_driver),
        input(:location_pickup),
        input(:location_dropoff),

        # The pre-agreed price of the trip.
        input(:price_cents),

        # The emoji representing the food item being delivered.
        input(:pickup_item),

        # Once the driver arrived at the pickup location, waiting for the food to be ready.
        compute(
          :waiting_for_food_at_restaurant,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:picked_up, fn x -> not provided?(x) end},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:restaurant_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> not provided?(x) end}
            ]
          }),
          &driver_at_restaurant/1
        ),

        # Once the driver arrived at the drop off location, waiting for the customer to come out and get the food.
        compute(
          :waiting_for_customer_at_dropoff,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:picked_up, &true?/1},
              {:dropped_off, fn x -> !true?(x) end}
            ]
          }),
          &driver_at_dropoff_location/1
        ),

        # Wait for the food at the restaurant.
        tick_once(
          :done_waiting_for_food_at_restaurant_timer,
          unblocked_when(:waiting_for_food_at_restaurant, &true?/1),
          &in_five_minutes/1
        ),
        mutate(
          :done_waiting_for_food_at_restaurant,
          [
            :done_waiting_for_food_at_restaurant_timer,
            :waiting_for_food_at_restaurant
          ],
          &record_driver_cancelled_time_after_waiting_for_food_at_restaurant/1,
          mutates: :driver_cancelled_time,
          update_revision_on_change: true
        ),

        # If the driver or restaurant cancel, record the time.
        input(:driver_cancelled_time),
        input(:restaurant_cancelled_time),

        # When the driver picks up or drops off the food, record the time.
        input(:picked_up),
        compute(:driver_reported_pickup_time, [:picked_up], &record_pickup_time/1),
        input(:dropped_off),
        compute(:driver_reported_dropoff_time, [:dropped_off], &record_dropoff_time/1),

        # Determine notable locations. staring point? pickup point? drop off point?
        compute(
          :current_location_label,
          [:location_driver],
          &compute_location_label/1
        ),
        compute(
          :en_route,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label, &en_route?/1}
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
              {:current_location_label, &at_starting_point?/1}
            ]
          }),
          fn _ -> {:ok, true} end
        ),
        compute(
          :reached_restaurant,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:current_location_label, &at_pick_up?/1}
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
              {:current_location_label, &at_drop_off?/1}
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
              {:restaurant_cancelled_time, fn x -> not provided?(x) end},
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
              {:restaurant_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_pickup_time, fn x -> provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &update_dropoff_eta/1
        ),

        # Continuously polling for driver's location and updating `location_driver`.
        tick_recurring(
          :driver_location_current_timer,
          unblocked_when({
            :and,
            [
              {:trip_completed_at, fn x -> not provided?(x) end},
              {:driver_cancelled_time, fn x -> not provided?(x) end},
              {:restaurant_cancelled_time, fn x -> not provided?(x) end},
              {:driver_reported_dropoff_time, fn x -> not provided?(x) end}
            ]
          }),
          &in_five_seconds/1
        ),
        mutate(
          :driver_location_current_update,
          [:driver_location_current_timer],
          &fetch_simulated_current_location/1,
          mutates: :location_driver,
          update_revision_on_change: true
        ),

        # Wait for the customer to come out and pickup the item for a few minutes.
        tick_once(
          :done_waiting_for_customer_timer,
          unblocked_when(:waiting_for_customer_at_dropoff, &true?/1),
          &in_five_minutes/1
        ),
        mutate(
          :done_waiting_for_customer,
          [:done_waiting_for_customer_timer, :waiting_for_customer_at_dropoff],
          &record_driver_asked_for_customer_to_leave/1,
          mutates: :dropped_off,
          update_revision_on_change: true
        ),

        # Once the drop off occurred, the payment is processed.
        compute(:payment, [:driver_reported_dropoff_time, :price_cents], &process_payment/1),
        compute(
          :trip_completed_at,
          unblocked_when({
            :or,
            [
              {:driver_cancelled_time, &provided?/1},
              {:restaurant_cancelled_time, &provided?/1},
              {:payment, &provided?/1}
            ]
          }),
          &now/1,
          f_on_save: fn trip, _params ->
            Logger.info("#{trip}: Notifying pubsub of trip completion")
            Phoenix.PubSub.broadcast(Rs.PubSub, "trip_completed", {:trip_completed, trip})
            {:ok, "trip completed"}
          end
        ),

        # Record the history of the trip.
        historian(
          :trip_history,
          unblocked_when({
            :or,
            [
              {:done_waiting_for_food_at_restaurant, &provided?/1},
              {:done_waiting_for_customer, &provided?/1},
              {:location_driver_initial, &provided?/1},
              {:driver_cancelled_time, &provided?/1},
              {:restaurant_cancelled_time, &provided?/1},
              {:picked_up, &provided?/1},
              {:dropped_off, &provided?/1},
              {:payment, &provided?/1},
              {:at_starting_point, &provided?/1},
              {:reached_restaurant, &provided?/1},
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
