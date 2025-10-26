## Rideshare Workflow Demo

This example shows a basic rideshare workflow, built with Journey.

In this example, we create a driver (Mario), and a passenger (Luigi), and match them for a trip -- which starts with Mario at location 10, Luigi looking to be picked up at location 16, and dropped off at location 21.

The log shows the trip starting and the driver driving to Luigi's pickup location.

Once Luigi is picked up, the driver takes Luigi to the drop off spot -- the logs show the tracking of similated GPS data.

Once Mario and Luigi arrive at the drop off spot, and Luigi exits the vehicle, Mario marks the passenger as dropped off, thus completing the trip, and triggering the payment.

```elixir
~/src/rideshare/rs $ iex -S mix
Erlang/OTP 27 [erts-15.2.3] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

2025-10-26 12:30:55.813 Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> driver = RS.Driver.new("Mario")
"DRIVERVXB7BZT2RLL9L6VBRDDM"
iex(2)> passenger = RS.Passenger.new("Luigi")
"PASSENGER3TMJ027H0795M8YAE3AA"
iex(3)> trip = RS.Trip.new(driver, passenger, 10, 19, 25, 98)
2025-10-26 12:31:33.940 Starting a new trip.

Driver: DRIVERVXB7BZT2RLL9L6VBRDDM
Current Driver Location: 10

Passenger: PASSENGER3TMJ027H0795M8YAE3AA
Pickup Location: 19
Dropoff Location: 25

Price: $98

"TRIPZY8Z221TE99GBTEY26RZ"
2025-10-26 12:31:38.990 Driving to pickup location 19. Currently at: 10. ETA: in 9.
2025-10-26 12:31:44.037 Driving to pickup location 19. Currently at: 11. ETA: in 8.
2025-10-26 12:31:44.052 Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-10-26 12:31:49.075 Driving to pickup location 19. Currently at: 12. ETA: in 7.
2025-10-26 12:31:54.120 Driving to pickup location 19. Currently at: 14. ETA: in 5.
2025-10-26 12:31:54.140 Driving to pickup location 19. Currently at: 15. ETA: in 4.
2025-10-26 12:31:59.168 Driving to pickup location 19. Currently at: 15. ETA: in 4.
2025-10-26 12:32:04.207 Driving to pickup location 19. Currently at: 17. ETA: in 2.
2025-10-26 12:32:04.226 Driving to pickup location 19. Currently at: 18. ETA: in 1.
2025-10-26 12:32:09.235 Driving to pickup location 19. Currently at: 18. ETA: in 1.
2025-10-26 12:32:14.277 Waiting for passenger at pickup location 19.
2025-10-26 12:32:19.344 Waiting for passenger at pickup location 19.
2025-10-26 12:32:19.363 Waiting for passenger at pickup location 19.
2025-10-26 12:32:24.402 Waiting for passenger at pickup location 19.
iex(4)> Journey.set(trip, :picked_up, true); :ok
:ok
2025-10-26 12:32:32.191 Driver picked up the passenger, at #DateTime<2025-10-26 12:32:32.186429-07:00 PDT America/Los_Angeles>.
2025-10-26 12:32:39.540 Driving passenger to drop off location 25. Currently at 20. ETA: in 5.
2025-10-26 12:32:44.584 Driving passenger to drop off location 25. Currently at 21. ETA: in 4.
2025-10-26 12:32:49.650 Driving passenger to drop off location 25. Currently at 22. ETA: in 3.
2025-10-26 12:32:54.709 Driving passenger to drop off location 25. Currently at 24. ETA: in 1.
2025-10-26 12:32:59.766 Waiting for passenger to exit the vehicle at the drop off location 25.
2025-10-26 12:32:59.796 Waiting for passenger to exit the vehicle at the drop off location 25.
2025-10-26 12:33:04.816 Waiting for passenger to exit the vehicle at the drop off location 25.
2025-10-26 12:33:09.860 Waiting for passenger to exit the vehicle at the drop off location 25.
2025-10-26 12:33:14.892 Waiting for passenger to exit the vehicle at the drop off location 25.
2025-10-26 12:33:14.906 Waiting for passenger to exit the vehicle at the drop off location 25.
iex(5)> Journey.set(trip, :dropped_off, true); :ok
2025-10-26 12:33:15.822 Driver dropped off the passenger, at #DateTime<2025-10-26 12:33:15.822349-07:00 PDT America/Los_Angeles>.
:ok
2025-10-26 12:33:15.834 Passenger dropped off.
Charging passenger `PASSENGER3TMJ027H0795M8YAE3AA` $98, to driver `DRIVERVXB7BZT2RLL9L6VBRDDM`.
The trip is now complete.

iex(6)> trip |> Journey.load() |> Journey.values()
%{
  driver_id: "DRIVERVXB7BZT2RLL9L6VBRDDM",
  created_at: 1761507093,
  execution_id: "TRIPZY8Z221TE99GBTEY26RZ",
  last_updated_at: 1761507199,
  driver_location_current: 25,
  dropoff_location: 25,
  passenger_id: "PASSENGER3TMJ027H0795M8YAE3AA",
  pickup_location: 19,
  price: 98,
  picked_up: true,
  driver_reported_pickup_time: 1761507152,
  dropped_off: true,
  driver_reported_dropoff_time: 1761507195,
  pickup_eta_schedule: 1761507154,
  dropoff_eta_schedule: 1761507199,
  driver_location_current_schedule: 1761507199,
  driver_location_current_update: "updated :driver_location_current",
  payment: "charged $98. passenger `PASSENGER3TMJ027H0795M8YAE3AA`, driver `DRIVERVXB7BZT2RLL9L6VBRDDM`"
}
iex(7)>
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


