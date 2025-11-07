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
        input(:started_in_time_zone),
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
        input(:item_to_deliver),

        # Once the driver arrived at the pickup location, waiting for the food to be ready.
        compute(
          :waiting_for_food_at_restaurant,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:picked_up, fn x -> not true?(x) end},
              {:driver_cancelled, fn x -> not true?(x) end},
              {:reached_restaurant, &true?/1}
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
              {:reached_dropoff_location, &true?/1},
              {:location_driver, &provided?/1},
              {:picked_up, &true?/1},
              {:dropped_off, fn x -> !true?(x) end}
            ]
          }),
          &driver_at_dropoff_location/1
        ),

        # Wait for the food at the restaurant.
        tick_once(
          :waiting_for_food_at_restaurant_timer,
          unblocked_when(:waiting_for_food_at_restaurant, &true?/1),
          &in_a_minute/1
        ),
        mutate(
          :waiting_for_food_at_restaurant_timeout,
          [
            :waiting_for_food_at_restaurant_timer,
            :waiting_for_food_at_restaurant
          ],
          &set_driver_cancelled/1,
          mutates: :driver_cancelled,
          update_revision_on_change: true
        ),

        # If the driver or restaurant cancel, record the time.
        input(:driver_cancelled),

        # When the driver picks up or drops off the food, record the time.
        input(:picked_up),
        input(:dropped_off),
        input(:handed_off),

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
        compute(
          :driving_to_pickup_log,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:driver_cancelled, fn x -> not true?(x) end},
              {:picked_up, fn x -> not true?(x) end}
            ]
          }),
          &log_driving_to_pickup/1
        ),
        compute(
          :driving_to_dropoff_log,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:driver_cancelled, fn x -> not true?(x) end},
              {:picked_up, fn x -> not true?(x) end},
              {:dropped_off, fn x -> not true?(x) end},
              {:handed_off, fn x -> not true?(x) end}
            ]
          }),
          &log_driving_to_dropoff/1
        ),

        # Continuously polling for driver's location and updating `location_driver`.
        tick_recurring(
          :driver_location_current_timer,
          unblocked_when({
            :and,
            [
              {:trip_completed_at, fn x -> not provided?(x) end},
              {:driver_cancelled, fn x -> not true?(x) end},
              {:dropped_off, fn x -> not true?(x) end},
              {:handed_off, fn x -> not true?(x) end}
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
          :waiting_for_customer_timer,
          unblocked_when(:waiting_for_customer_at_dropoff, &true?/1),
          &in_a_minute/1
        ),
        mutate(
          :waiting_for_customer_timeout,
          unblocked_when({
            :and,
            [
              {:waiting_for_customer_timer, &provided?/1},
              {:waiting_for_customer_at_dropoff, &true?/1},
              {:handed_off, fn x -> not provided?(x) end}
            ]
          }),
          fn _ -> {:ok, true} end,
          mutates: :dropped_off,
          update_revision_on_change: true
        ),

        # Once the drop off occurred, the payment is processed.
        compute(
          :payment,
          unblocked_when({
            :and,
            [
              {:price_cents, &provided?/1},
              {
                :or,
                [
                  {:dropped_off, &true?/1},
                  {:handed_off, &true?/1}
                ]
              }
            ]
          }),
          &process_payment/1
        ),
        compute(
          :trip_completed_at,
          unblocked_when({
            :or,
            [
              {:driver_cancelled, &true?/1},
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
              {:current_location_label, &provided?/1},
              {:waiting_for_food_at_restaurant_timeout, &provided?/1},
              {:waiting_for_customer_timeout, &provided?/1},
              {:waiting_for_food_at_restaurant, &true?/1},
              {:driver_cancelled, &true?/1},
              {:picked_up, &provided?/1},
              {:dropped_off, &provided?/1},
              {:handed_off, &provided?/1},
              {:payment, &provided?/1},
              {:reached_restaurant, &provided?/1},
              {:reached_dropoff_location, &provided?/1},
              {:waiting_for_customer_at_dropoff, &true?/1},
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
