## Delivery Trip Workflow Demo

This example models a basic delivery trip workflow -- driving to pickup location, item pickup, driving to destination, handing off or dropping off the item, payment.

The definition of the workflow can be found in [lib/rs/trip/graph.ex](./lib/rs/trip/graph.ex), and the example below illustrates running an execution of this workflow, which gets created once the driver and the order get matched.

The workflow is built with [Journey](https://hexdocs.pm/journey), an Elixir package for defining and executing Persisted Distributed Reactive Graphs, so I didn't need to write much code for
* persistence (db schemas),
* scheduling one-time and recurring tasks,
* orchestrating conditional events and dependencies,
* structuring the code of orchestration logic and computations,
* retries and crash recovery,
* distribution and horizontal scalability,

while keeping the application concise, self-documented (see the graph), and naturally scalable – resilient, durable executions in a package. When / if we wire up LiveView UI for managing trips, we can use Journey's [f_on_save](https://hexdocs.pm/journey/search.html?q=f_on_save) functions generate PubSub notifications, to trigger UI updates.

The log shows the trip starting and the driver driving to pickup location.

Once the item is picked up, the driver takes it to the drop off spot -- the logs show the tracking of simulated GPS data.

Once the item arrives at the drop off spot, the driver either hands off the item to the customer, or drops it off, thus completing the trip, and triggering the payment.

```elixir
~/src/delivery/rs $ iex -S mix
Erlang/OTP 27 [erts-15.2.3] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

2025-10-31 07:50:29.341 [info] Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> trip = RS.Trip.new("driver1", "order1", 10, 19, 25, 98)
2025-10-31 07:51:16.301 [info] Starting a new trip.

Driver: driver1
Current Driver Location: 10

Order: order1
Pickup Location: 19
Dropoff Location: 25

Price: $0.98

2025-10-31 07:51:16.391 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 10. ETA: in 9.
"TRIP4862ELGAYZXDYL7A95H9"
2025-10-31 07:51:21.635 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 11. ETA: in 8.
2025-10-31 07:51:26.696 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-10-31 07:51:26.718 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-10-31 07:51:31.748 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 13. ETA: in 6.
2025-10-31 07:51:36.792 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 14. ETA: in 5.
2025-10-31 07:51:36.808 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 14. ETA: in 5.
2025-10-31 07:51:41.849 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 15. ETA: in 4.
2025-10-31 07:51:41.875 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 15. ETA: in 4.
2025-10-31 07:51:46.895 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 16. ETA: in 3.
2025-10-31 07:51:51.949 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 17. ETA: in 2.
2025-10-31 07:51:51.971 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 17. ETA: in 2.
2025-10-31 07:51:56.998 [info] TRIP4862ELGAYZXDYL7A95H9: Driving to pickup location 19. Currently at: 18. ETA: in 1.
2025-10-31 07:52:02.017 [info] TRIP4862ELGAYZXDYL7A95H9: Waiting at pickup location 19.
2025-10-31 07:52:02.018 [info] TRIP4862ELGAYZXDYL7A95H9: Driver is at pickup location 19
iex(2)> Journey.set("TRIP4862ELGAYZXDYL7A95H9", :picked_up, true); :ok
:ok
2025-10-31 07:52:25.552 [info] TRIP4862ELGAYZXDYL7A95H9: Driver picked up the item, at #DateTime<2025-10-31 05:52:25.546099-07:00 PDT America/Los_Angeles>.
2025-10-31 07:52:25.564 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 19. ETA: in 6.
2025-10-31 07:52:27.235 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 20. ETA: in 5.
2025-10-31 07:52:32.286 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 21. ETA: in 4.
2025-10-31 07:52:37.326 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 22. ETA: in 3.
2025-10-31 07:52:42.382 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 23. ETA: in 2.
2025-10-31 07:52:47.432 [info] TRIP4862ELGAYZXDYL7A95H9: Driving item to drop off location 25. Currently at 24. ETA: in 1.
2025-10-31 07:52:52.494 [info] TRIP4862ELGAYZXDYL7A95H9: Waiting for the customer to come pick up the item at the drop off location 25.
2025-10-31 07:52:52.494 [info] TRIP4862ELGAYZXDYL7A95H9: Driver is at dropoff location 25
iex(3)> Journey.set("TRIP4862ELGAYZXDYL7A95H9", :dropped_off, true); :ok
2025-10-31 07:53:04.941 [info] TRIP4862ELGAYZXDYL7A95H9: Driver handed the item off to the customer, at #DateTime<2025-10-31 05:53:04.941658-07:00 PDT America/Los_Angeles>.
:ok
2025-10-31 07:53:04.956 [info] TRIP4862ELGAYZXDYL7A95H9:
Item dropped off.
Charging `order1` $0.98, to driver `driver1`.
The trip is now complete.

2025-10-31 07:53:04.975 [info] TRIP4862ELGAYZXDYL7A95H9: Notifying pubsub of trip completion
iex(4)> "TRIP4862ELGAYZXDYL7A95H9" |> Journey.load() |> Journey.values()
%{
  driver_id: "driver1",
  created_at: 1761915076,
  order_id: "order1",
  location_driver_initial: 10,
  location_driver: 25,
  location_pickup: 19,
  location_dropoff: 25,
  price_cents: 98,
  driver_reported_pickup_time: 1761915145,
  picked_up: true,
  dropped_off: true,
  done_waiting_for_food_at_restaurant_schedule: 1761915182,
  driver_reported_dropoff_time: 1761915184,
  current_location_label: "drop off point",
  reached_dropoff_location: true,
  trip_completed_at: 1761915184,
  driver_location_current_schedule: 1761915187,
  driver_location_current_update: "updated :location_driver",
  done_waiting_for_customer_schedule: 1761915232,
  payment: "charged $0.98. pickup `order1`, driver `driver1`",
  trip_history: [
    %{
      "metadata" => nil,
      "node" => "trip_completed_at",
      "revision" => 309,
      "timestamp" => 1761915184,
      "value" => 1761915184
    },
    %{
      "metadata" => nil,
      "node" => "payment",
      "revision" => 305,
      "timestamp" => 1761915184,
      "value" => "charged $0.98. pickup `order1`, driver `driver1`"
    },
    %{
      "metadata" => nil,
      "node" => "dropped_off",
      "revision" => 297,
      "timestamp" => 1761915184,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "reached_dropoff_location",
      "revision" => 286,
      "timestamp" => 1761915172,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "en_route",
      "revision" => 208,
      "timestamp" => 1761915147,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "picked_up",
      "revision" => 180,
      "timestamp" => 1761915145,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "reached_restaurant",
      "revision" => 161,
      "timestamp" => 1761915122,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "en_route",
      "revision" => 35,
      "timestamp" => 1761915081,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "at_starting_point",
      "revision" => 15,
      "timestamp" => 1761915076,
      "value" => true
    },
    %{
      "metadata" => nil,
      "node" => "location_driver_initial",
      "revision" => 3,
      "timestamp" => 1761915076,
      "value" => 10
    }
  ],
  execution_id: "TRIP4862ELGAYZXDYL7A95H9",
  last_updated_at: 1761915187
}
iex(5)>
```

# Rs

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
