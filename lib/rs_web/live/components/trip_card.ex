defmodule RsWeb.Live.Components.TripCard do
  use RsWeb, :html
  require Logger
  import RsWeb.Live.Classes

  @moduledoc false

  def render(assigns) do
    ~H"""
    <div class="m-3">
      <div
        id={"trip-card-container-#{@trip}-id"}
        class={
          [section2_no_margin(), "relative"] ++
            if @trip_values.trip_completed_at != nil, do: ["text-secondary-content/40"], else: [""]
        }
      >
        <h1 class="mb-2 pb-2 flex items-center">
          <span><span class={data_point()}>{@trip}</span></span>
          <span :if={@trip_values.trip_completed_at == nil} class="ml-auto flex items-center gap-2">
            <span>in progress</span>
            <span class="font-mono status status-success status-md animate-ping"></span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment != nil}
            class="ml-auto flex items-center gap-2"
          >
            <span>completed</span>
            <span class="font-mono badge badge-success">${@trip_values.price}</span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment == nil}
            class="ml-auto flex items-center gap-2"
          >
            <span>completed</span>
            <span class="font-mono text-secondary-content">◯</span>
          </span>
        </h1>
        <div class="text-xs font-mono">
          <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
            <% marker =
              cond do
                i == @trip_values.location_pickup and @trip_values.done_waiting_for_passenger_at_pickup != nil -> "?"
                i == @trip_values.location_pickup and @trip_values.picked_up == true -> "o"
                i == @trip_values.location_pickup and @trip_values.picked_up != true -> "🧍"
                i == @trip_values.location_dropoff and @trip_values.dropped_off == true -> "🧍"
                i == @trip_values.location_dropoff and @trip_values.dropped_off != true -> "📍"
                true -> "."
              end %>
            <span class="font-mono">{marker}</span>
          <% end %>
        </div>
        <div class="text-xs font-mono">
          <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
            <%= if i == @trip_values.location_driver and @trip_values.trip_completed_at == nil do %>
              <span class="font-mono animate-pulse">🚗</span>
            <% else %>
              <span class="font-mono">.</span>
            <% end %>
          <% end %>
        </div>
        <div class="mt-1 pt-1">
          <.button
            disabled={
              @trip_values.picked_up == true or @trip_values.waiting_for_passenger_at_pickup != true or
                @trip_values.trip_completed_at != nil
            }
            id={"pickup-passenger1-#{@trip}"}
            phx-click="pickup_customer"
            phx-value-trip={@trip}
            class="btn btn-sm btn-success my-2 py-2"
          >
            Pick Up
          </.button>
          <.button
            disabled={@trip_values.waiting_for_passenger_at_dropoff != true or @trip_values.trip_completed_at != nil}
            id={"drop-off-passenger1-#{@trip}"}
            phx-click="dropoff_customer"
            phx-value-trip={@trip}
            class="btn btn-sm btn-success my-2 py-2"
          >
            Drop Off
          </.button>
        </div>

        <div class="font-mono my-1 py-1">
          <span class="font-mono badge badge-neutral">
            <.icon name="hero-map" class="w-4 h-4" /> {@trip_values.location_driver}
          </span>
          <span :if={@trip_values.trip_completed_at != nil} class="font-mono badge badge-neutral">
            <.icon name="hero-clock" class="w-4 h-4" />{@trip_values.trip_completed_at - @trip_values.created_at}s
          </span>
          <span :if={@trip_values.trip_completed_at == nil} class="font-mono badge badge-neutral">
            <.icon name="hero-clock" class="w-4 h-4" />{@trip_values.last_updated_at - @trip_values.created_at}s
          </span>
          <div
            :if={@trip_values.waiting_for_passenger_at_pickup == true and @trip_values.trip_completed_at == nil}
            class="font-mono badge badge-info"
          >
            Waiting for Passenger at pickup location.
          </div>
          <div
            :if={@trip_values.picked_up == true}
            class="font-mono badge badge-neutral"
          >
            Picked Up
          </div>
          <div
            :if={@trip_values.dropped_off == true}
            class="font-mono badge badge-neutral"
          >
            Dropped Off
          </div>
          <span
            :if={@trip_values.done_waiting_for_passenger_at_pickup != nil and @trip_values.trip_completed_at != nil}
            class="font-mono badge badge-warning"
          >
            Passenger no show
          </span>

          <span :if={@trip_values.waiting_for_passenger_at_dropoff == true} class="font-mono badge badge-info">
            ⌛️ Waiting for Passenger to exit.
          </span>
          <span :if={@trip_values.done_waiting_for_passenger_to_leave != nil} class="font-mono badge badge-neutral">
            👋
          </span>
          <div
            :if={@trip_values.payment != nil}
            class="font-mono badge badge-neutral"
          >
            Paid
          </div>
          <.link
            :if={@embedded}
            navigate={"/trip/#{@trip}?show_details=true"}
            class="absolute bottom-2 right-2 hover:opacity-70 transition-opacity p-2"
          >
            <.icon name="hero-arrows-pointing-out" class="w-6 h-6" />
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
