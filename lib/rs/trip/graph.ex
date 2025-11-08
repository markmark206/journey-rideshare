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
        # Capture the creation time of the trip.
        compute(:created_at, [], &now/1),

        # Initial parameters of the trip.
        input(:started_in_time_zone),
        input(:driver_id),
        input(:order_id),

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

        # If we reached the end of the wait (and no food showed up), mark the trip as cancelled by the driver.
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

        # This flag indicates that the driver has picked up the item.
        input(:picked_up),

        # Possible trip outcomes.
        input(:driver_cancelled),
        input(:dropped_off),
        input(:handed_off),

        # Determine notable locations. staring point? pickup point? drop off point?
        compute(
          :current_location_label,
          [:location_driver],
          &compute_location_label/1
        ),

        # The driver has reached the restaurant.
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

        # The driver has reached the drop off location.
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

        # Log the driving to the pickup location.
        # This node is here exclusively for the logging side effect.
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

        # Log the driving to the drop off location.
        # This node is here exclusively for the logging side effect.
        compute(
          :driving_to_dropoff_log,
          unblocked_when({
            :and,
            [
              {:location_driver, &provided?/1},
              {:driver_cancelled, fn x -> not true?(x) end},
              {:picked_up, &true?/1},
              {:dropped_off, fn x -> not true?(x) end},
              {:handed_off, fn x -> not true?(x) end}
            ]
          }),
          &log_driving_to_dropoff/1
        ),

        # Continuously polling for driver's location and updating `location_driver`.
        # Here we are using a simulated "GPS" system that updates the driver's location every 5 seconds.
        # TODO: move this out of the graph (into the "driver" graph)
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
        # Whenever the timer fires, store the updated "location" in the `location_driver` node.
        mutate(
          :driver_location_current_update,
          [:driver_location_current_timer],
          &fetch_simulated_current_location/1,
          mutates: :location_driver,
          update_revision_on_change: true
        ),

        # Wait for the customer to come out and pickup the item.
        tick_once(
          :waiting_for_customer_timer,
          unblocked_when(:waiting_for_customer_at_dropoff, &true?/1),
          &in_a_minute/1
        ),

        # If the customer didn't come out, and we reached the end of the wait, "drop off" the item at the door.
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

        # Once the drop off or hand off occurred, the payment is processed.
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

        # If the trip was cancelled, or the payment was collected, the trip is all done! Record the completion time.
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
          # Have pubsub notify anyone interested (e.g. liveviews that are tracking trip completions) that the trip is complete.
          f_on_save: fn trip, _params ->
            Logger.info("#{trip}: Notifying pubsub of trip completion")
            Phoenix.PubSub.broadcast(Rs.PubSub, "trip_completed", {:trip_completed, trip})
            {:ok, "trip completed"}
          end
        ),

        # Record the history of the trip.
        # The historian node will record any changes to its unlocked_when() nodes.
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
      # Have pubsub notify anyone interested (e.g. liveviews that are watching this trip) that the trip has updated.
      f_on_save: &notify_pubsub_of_trip_update/3,
      execution_id_prefix: @graph_name
    )
  end
end
