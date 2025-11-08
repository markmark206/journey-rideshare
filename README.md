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
💙💛 [markmark ~/src/rideshare/rs][simpler-graph][S] $ iex -S mix
Erlang/OTP 27 [erts-15.2.3] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

Compiling 2 files (.ex)
Generated rs app
2025-11-08 02:23:14.904 pid=<0.296.0> [info] Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> trip = RS.Trip.new("driver1", "order1", 1, 5, 9, 98, "🍕", "America/Los_Angeles")
2025-11-08 02:23:51.907 pid=<0.429.0> [info] Starting a new trip.

Driver: driver1
Current Driver Location: 1

Order: order1
Pickup Location: 5
Dropoff Location: 9

Price: $0.98
Item: 🍕
Started in Time Zone: America/Los_Angeles

2025-11-08 02:23:51.997 pid=<0.453.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving to pickup location 5. Currently at: 1. ETA: in 4.
"TRIP4Y18GX0H69JDXH3122YM"
2025-11-08 02:23:56.174 pid=<0.483.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving to pickup location 5. Currently at: 2. ETA: in 3.
2025-11-08 02:24:01.201 pid=<0.532.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving to pickup location 5. Currently at: 3. ETA: in 2.
2025-11-08 02:24:01.223 pid=<0.550.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving to pickup location 5. Currently at: 3. ETA: in 2.
2025-11-08 02:24:06.236 pid=<0.572.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving to pickup location 5. Currently at: 4. ETA: in 1.
2025-11-08 02:24:11.278 pid=<0.603.0> [info] TRIP4Y18GX0H69JDXH3122YM: Waiting at pickup location 5.
2025-11-08 02:24:11.305 pid=<0.632.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driver is at pickup location 5
iex(2)> Journey.set("TRIP4Y18GX0H69JDXH3122YM", :picked_up, true); :ok
2025-11-08 02:24:15.891 pid=<0.662.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving item to drop off location 9. Currently at 5. ETA: in 4.
:ok
2025-11-08 02:24:16.320 pid=<0.683.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving item to drop off location 9. Currently at 6. ETA: in 3.
2025-11-08 02:24:21.352 pid=<0.717.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving item to drop off location 9. Currently at 7. ETA: in 2.
2025-11-08 02:24:26.388 pid=<0.741.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driving item to drop off location 9. Currently at 8. ETA: in 1.
2025-11-08 02:24:31.424 pid=<0.775.0> [info] TRIP4Y18GX0H69JDXH3122YM: Waiting for the customer to come pick up the item at the drop off location 9.
2025-11-08 02:24:31.450 pid=<0.797.0> [info] TRIP4Y18GX0H69JDXH3122YM: Driver is at dropoff location 9
iex(3)> Journey.set("TRIP4Y18GX0H69JDXH3122YM", :handed_off, true); :ok
2025-11-08 02:24:34.801 pid=<0.820.0> [info] TRIP4Y18GX0H69JDXH3122YM:
Item handed off.
Charging `order1` $0.98, to driver `driver1`.
The trip is now complete.

:ok
2025-11-08 02:24:34.818 pid=<0.835.0> [info] TRIP4Y18GX0H69JDXH3122YM: Notifying pubsub of trip completion
iex(4)> Journey.load("TRIP4Y18GX0H69JDXH3122YM") |> Journey.values()
%{
  driver_id: "driver1",
  created_at: 1762597431,
  started_in_time_zone: "America/Los_Angeles",
  order_id: "order1",
  location_driver_initial: 1,
  location_driver: 9,
  location_pickup: 5,
  location_dropoff: 9,
  price_cents: 98,
  item_to_deliver: "🍕",
  picked_up: true,
  waiting_for_customer_at_dropoff: true,
  reached_dropoff_location: true,
  waiting_for_food_at_restaurant_timer: 1762597511,
  handed_off: true,
  current_location_label: "drop off point",
  execution_id: "TRIP4Y18GX0H69JDXH3122YM",
  driver_location_current_timer: 1762597476,
  trip_completed_at: 1762597474,
  driver_location_current_update: "updated :location_driver",
  waiting_for_customer_timer: 1762597531,
  payment: "charged $0.98. pickup `order1`, driver `driver1`",
  trip_history: [
    %{
      "metadata" => nil,
      "node" => "trip_completed_at",
      "revision" => 138,
      "timestamp" => 1762597474,
      "value" => 1762597474
    },
    %{
      "metadata" => nil,
      "node" => "payment",
      "revision" => 134,
      "timestamp" => 1762597474,
      "value" => "charged $0.98. pickup `order1`, driver `driver1`"
    },
    %{
      "metadata" => nil,
      "node" => "handed_off",
      "revision" => 130,
      "timestamp" => 1762597474,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "waiting_for_customer_at_dropoff",
      "revision" => 125,
      "timestamp" => 1762597471,
      "value" => true
    },    
    ...
```

## References

* Play with this application live: https://delivery.demo.gojourney.dev/
* Source code for this application: https://github.com/markmark206/journey-food-delivery
* Journey docs: https://hexdocs.pm/journey/readme.html
* Journey codebase: https://github.com/markmark206/journey
