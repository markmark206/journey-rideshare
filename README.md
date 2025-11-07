## Delivery Trip Workflow Demo

This example models a basic delivery trip workflow -- driving to pickup location, item pickup, driving to destination, handing off or dropping off the item, payment.

## Running the App

Example:

(output omitted for brevity)

```
~/src/delivery $ source ./.env
💙💛 ~/src/delivery $ mix setup
💙💛 ~/src/delivery $ mix phx.server
2025-11-05 10:01:39.848 [info] Migrations already up
2025-11-05 10:01:40.577 [info] Running RsWeb.Endpoint with Bandit 1.8.0 at 127.0.0.1:4000 (http)
2025-11-05 10:01:40.578 [info] Access RsWeb.Endpoint at http://localhost:4000
...
```
You can now navigate to http://localhost:4000 and start a few deliveries, usher them through, and watch them run their course.

## Implementation

The definition of the workflow can be found in [lib/rs/trip/graph.ex](./lib/rs/trip/graph.ex), and the example below illustrates running an execution of this workflow, which gets created once the driver and the order get matched.

The workflow is built with [Journey](https://hexdocs.pm/journey), an Elixir package for defining and executing Persisted Distributed Reactive Graphs, so I didn't need to write much code for
* persistence (db schemas),
* scheduling one-time and recurring tasks,
* orchestrating conditional events and dependencies,
* structuring the code of orchestration logic and computations,
* retries and crash recovery,
* distribution and horizontal scalability,

while keeping the application concise, self-documented (see the graph), and naturally scalable – resilient, durable executions in a package. Journey's [f_on_save](https://hexdocs.pm/journey/search.html?q=f_on_save) functions generate PubSub notifications which trigger UI updates.

The log shows the trip starting and the driver driving to pickup location.

Once the item is picked up, the driver takes it to the drop off spot -- the logs show the tracking of simulated GPS data.

Once the item arrives at the drop off spot, the driver either hands off the item to the customer, or drops it off, thus completing the trip, and triggering the payment.

```elixir
💙💛 [markmark ~/src/rideshare/rs][main][U] $ iex -S mix
Erlang/OTP 27 [erts-15.2.3] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

2025-11-05 10:07:13.628 [info] Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex> trip = RS.Trip.new("driver1", "order1", 10, 19, 25, 98, "🍕", "America/Los_Angeles")
2025-11-05 10:08:44.544 [info] Starting a new trip.

Driver: driver1
Current Driver Location: 10

Order: order1
Pickup Location: 19
Dropoff Location: 25

Price: $0.98
Item: 🍕
Started in Time Zone: America/Los_Angeles

2025-11-05 10:08:44.638 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 10. ETA: in 9.
"TRIPX6JHTJ669Y312HADLHD1"
2025-11-05 10:08:52.156 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 11. ETA: in 8.
2025-11-05 10:08:57.197 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-11-05 10:08:57.219 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-11-05 10:09:02.292 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 13. ETA: in 6.
2025-11-05 10:09:07.335 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 14. ETA: in 5.
2025-11-05 10:09:07.353 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 14. ETA: in 5.
2025-11-05 10:09:12.387 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 15. ETA: in 4.
2025-11-05 10:09:17.412 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 16. ETA: in 3.
2025-11-05 10:09:22.449 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 17. ETA: in 2.
2025-11-05 10:09:27.492 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 18. ETA: in 1.
2025-11-05 10:09:27.511 [info] TRIPX6JHTJ669Y312HADLHD1: Driving to pickup location 19. Currently at: 18. ETA: in 1.
2025-11-05 10:09:32.542 [info] TRIPX6JHTJ669Y312HADLHD1: Driver is at pickup location 19
2025-11-05 10:09:32.542 [info] TRIPX6JHTJ669Y312HADLHD1: Waiting at pickup location 19.
iex> Journey.set("TRIPX6JHTJ669Y312HADLHD1", :picked_up, true); :ok
:ok
2025-11-05 10:09:38.111 [info] TRIPX6JHTJ669Y312HADLHD1: Driver picked up the item, at #DateTime<2025-11-05 10:09:38.104376-08:00 PST America/Los_Angeles>.
2025-11-05 10:09:38.120 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 19. ETA: in 6.
2025-11-05 10:09:42.641 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 20. ETA: in 5.
2025-11-05 10:09:47.703 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 21. ETA: in 4.
2025-11-05 10:09:52.741 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 22. ETA: in 3.
2025-11-05 10:09:52.757 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 22. ETA: in 3.
2025-11-05 10:09:57.771 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 23. ETA: in 2.
2025-11-05 10:09:57.791 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 23. ETA: in 2.
2025-11-05 10:10:02.803 [info] TRIPX6JHTJ669Y312HADLHD1: Driving item to drop off location 25. Currently at 24. ETA: in 1.
2025-11-05 10:10:07.872 [info] TRIPX6JHTJ669Y312HADLHD1: Waiting for the customer to come pick up the item at the drop off location 25.
2025-11-05 10:10:07.873 [info] TRIPX6JHTJ669Y312HADLHD1: Driver is at dropoff location 25
iex(5)> Journey.set("TRIPX6JHTJ669Y312HADLHD1", :dropped_off, true); :ok
2025-11-05 10:10:44.430 [info] TRIPX6JHTJ669Y312HADLHD1: Driver handed the item off to the customer, at #DateTime<2025-11-05 10:10:44.430452-08:00 PST America/Los_Angeles>.
:ok
2025-11-05 10:10:44.445 [info] TRIPX6JHTJ669Y312HADLHD1:
Item dropped off.
Charging `order1` $0.98, to driver `driver1`.
The trip is now complete.

2025-11-05 10:10:44.465 [info] TRIPX6JHTJ669Y312HADLHD1: Notifying pubsub of trip completion
iex> "TRIPX6JHTJ669Y312HADLHD1" |> Journey.load() |> Journey.values()
%{
  driver_id: "driver1",
  created_at: 1762366124,
  started_in_time_zone: "America/Los_Angeles",
  order_id: "order1",
  location_driver_initial: 10,
  location_driver: 25,
  location_pickup: 19,
  location_dropoff: 25,
  price_cents: 98,
  pickup_item: "🍕",
  driver_reported_pickup_time: 1762366178,
  picked_up: true,
  dropped_off: true,
  done_waiting_for_food_at_restaurant_timer: 1762366232,
  driver_reported_dropoff_time: 1762366244,
  current_location_label: "drop off point",
  reached_dropoff_location: true,
  trip_completed_at: 1762366244,
  driver_location_current_timer: 1762366248,
  driver_location_current_update: "updated :location_driver",
  done_waiting_for_customer_timer: 1762366267,
  payment: "charged $0.98. pickup `order1`, driver `driver1`",
  trip_history: [
    %{
      "metadata" => nil,
      "node" => "trip_completed_at",
      "revision" => 310,
      "timestamp" => 1762366244,
      "value" => 1762366244
    },
    %{
      "metadata" => nil,
      "node" => "payment",
      "revision" => 306,
      "timestamp" => 1762366244,
      "value" => "charged $0.98. pickup `order1`, driver `driver1`"
    },
    %{
      "metadata" => nil,
      "node" => "dropped_off",
      "revision" => 298,
      "timestamp" => 1762366244,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "reached_dropoff_location",
      "revision" => 270,
      "timestamp" => 1762366207,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "en_route",
      "revision" => 192,
      "timestamp" => 1762366182,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "picked_up",
      "revision" => 162,
      "timestamp" => 1762366178,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "reached_restaurant",
      "revision" => 155,
      "timestamp" => 1762366172,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "en_route",
      "revision" => 34,
      "timestamp" => 1762366132,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "at_starting_point",
      "revision" => 15,
      "timestamp" => 1762366124,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "location_driver_initial",
      "revision" => 4,
      "timestamp" => 1762366124,
      "value" => 10
    }
  ],
  execution_id: "TRIPX6JHTJ669Y312HADLHD1",
  last_updated_at: 1762366248
}
iex(7)>
```

## References

* Play with this application live: https://delivery.demo.gojourney.dev/
* Source code for this application: https://github.com/markmark206/journey-food-delivery
* Journey docs: https://hexdocs.pm/journey/readme.html
* Journey codebase: https://github.com/markmark206/journey
