## Rideshare Workflow Demo

This example shows a basic rideshare workflow, built with Journey.

In this example, we create a driver (Mario), and a customer (Luigi), and match them for a trip -- which starts with Mario at location 10, Luigi looking to be picked up at location 16, and dropped off at location 21.

The log shows the trip starting and the driver driving to Luigi's pickup location.

Once Luigi is picked up, the driver takes Luigi to the drop off spot -- the logs show the tracking of similated GPS data.

Once Mario and Luigi arrive at the drop off spot, and Luigi exits the vehicle, Mario marks the passenger as dropped off, thus completing the trip, and triggering the payment.

```elixir
~/src/rideshare/rs $ iex -S mix
Erlang/OTP 27 [erts-15.2.3] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1] [jit]

DEV 2025-10-26 03:33:29.321 [info] pid=<0.327.0> mfa=Ecto.Migrator.log/2  Migrations already up
Interactive Elixir (1.19.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> driver = RS.Driver.new("Mario")
"DRIVER1ZYDM1Z2J0HGG662HXX4"
iex(2)> customer = RS.Customer.new("Luigi")
"CUSTOMER0BZAYJLM4TGLAX62HB03"
iex(3)> trip = RS.Trip.new(driver, customer, 10, 16, 21)
DEV 2025-10-26 03:34:20.534 [info] pid=<0.388.0> mfa=RS.Trip.new/6  Starting a new trip.

Driver: DRIVER1ZYDM1Z2J0HGG662HXX4
Current Driver Location: 10

Customer: CUSTOMER0BZAYJLM4TGLAX62HB03
Pickup Location: 16
Dropoff Location: 21

Price: $100

"TRIPBGRBTGDD30H7J7JGD0BG"
DEV 2025-10-26 03:34:26.546 [info] pid=<0.438.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 6. current location: 10
DEV 2025-10-26 03:34:31.608 [info] pid=<0.459.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 5. current location: 11
DEV 2025-10-26 03:34:36.646 [info] pid=<0.479.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 4. current location: 12
DEV 2025-10-26 03:34:36.665 [info] pid=<0.488.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 3. current location: 13
DEV 2025-10-26 03:34:41.682 [info] pid=<0.500.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 3. current location: 13
DEV 2025-10-26 03:34:41.699 [info] pid=<0.509.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 2. current location: 14
DEV 2025-10-26 03:34:46.724 [info] pid=<0.520.0> mfa=RS.Trip.Logic.update_pickup_eta/1  driving to pickup location (16). pickup ETA: 2. current location: 14
DEV 2025-10-26 03:34:51.769 [info] pid=<0.541.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:34:51.792 [info] pid=<0.549.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:34:56.819 [info] pid=<0.562.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:35:01.861 [info] pid=<0.582.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:35:01.871 [info] pid=<0.591.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:35:06.913 [info] pid=<0.604.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:35:06.932 [info] pid=<0.612.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
DEV 2025-10-26 03:35:11.952 [info] pid=<0.624.0> mfa=RS.Trip.Logic.update_pickup_eta/1  waiting for the customer at the pickup location (16).
iex(4)> Journey.set(trip, :driver_reported_pickup_time, System.system_time(:second)); :ok
:ok
DEV 2025-10-26 03:35:22.050 [info] pid=<0.673.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  transporting passenger to drop off location (21). drop off ETA: 4 (current location: 17)
DEV 2025-10-26 03:35:27.093 [info] pid=<0.693.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  transporting passenger to drop off location (21). drop off ETA: 3 (current location: 18)
DEV 2025-10-26 03:35:32.128 [info] pid=<0.716.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  transporting passenger to drop off location (21). drop off ETA: 1 (current location: 20)
DEV 2025-10-26 03:35:32.140 [info] pid=<0.724.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  waiting for the customer to exit the vehicle at the drop off location (21).
DEV 2025-10-26 03:35:37.162 [info] pid=<0.737.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  waiting for the customer to exit the vehicle at the drop off location (21).
DEV 2025-10-26 03:35:37.180 [info] pid=<0.744.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  waiting for the customer to exit the vehicle at the drop off location (21).
DEV 2025-10-26 03:35:42.204 [info] pid=<0.757.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  waiting for the customer to exit the vehicle at the drop off location (21).
DEV 2025-10-26 03:35:42.224 [info] pid=<0.765.0> mfa=RS.Trip.Logic.update_dropoff_eta/1  waiting for the customer to exit the vehicle at the drop off location (21).
iex(5)> Journey.set(trip, :driver_reported_dropoff_time, System.system_time(:second)); :ok
DEV 2025-10-26 03:35:45.996 [info] pid=<0.777.0> mfa=RS.Trip.Logic.process_payment/1  customer dropped off. charging customer `CUSTOMER0BZAYJLM4TGLAX62HB03` 100, to driver `DRIVER1ZYDM1Z2J0HGG662HXX4`
:ok
iex(6)>
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


