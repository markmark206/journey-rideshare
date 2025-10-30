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
            <span class="font-mono status status-success status-md animate-pulse"></span>
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
            phx-click="on_pickup_customer_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            Pick Up
          </.button>
          <.button
            disabled={@trip_values.waiting_for_passenger_at_dropoff != true or @trip_values.trip_completed_at != nil}
            id={"drop-off-passenger1-#{@trip}"}
            phx-click="on_dropoff_customer_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            Drop Off
          </.button>
        </div>

        <div class="font-mono my-1 py-1">
          <div class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <span class="font-mono badge badge-neutral">
                <.icon name="hero-map" class="w-4 h-4" /> {@trip_values.location_driver}
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">
                {if @trip_values.trip_completed_at != nil, do: "Last known location", else: "Current driver location"}
              </p>
            </div>
          </div>
          <div class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <span :if={@trip_values.trip_completed_at != nil} class="font-mono badge badge-neutral">
                <.icon name="hero-clock" class="w-4 h-4" />{@trip_values.trip_completed_at - @trip_values.created_at}s
              </span>
              <span :if={@trip_values.trip_completed_at == nil} class="font-mono badge badge-neutral">
                <.icon name="hero-clock" class="w-4 h-4" />{@trip_values.last_updated_at - @trip_values.created_at}s
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Trip duration</p>
            </div>
          </div>
          <div
            :if={@trip_values.waiting_for_passenger_at_pickup == true and @trip_values.trip_completed_at == nil}
            class="font-mono badge badge-info"
          >
            <span class="animate-pulse">⌛️</span> Waiting for Passenger
          </div>
          <div :if={@trip_values.picked_up == true} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-neutral">
                Picked Up
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">The passenger was picked up</p>
            </div>
          </div>

          <div
            :if={@trip_values.done_waiting_for_passenger_at_pickup != nil and @trip_values.trip_completed_at != nil}
            class="dropdown dropdown-top inline-block"
          >
            <label tabindex="0">
              <span class="font-mono badge badge-warning">
                No show
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Passenger did not show up</p>
            </div>
          </div>

          <span :if={@trip_values.waiting_for_passenger_at_dropoff == true} class="font-mono badge badge-info">
            <span class="animate-pulse">⌛️</span> Waiting for Passenger to exit
          </span>
          <div :if={@trip_values.done_waiting_for_passenger_to_leave != nil} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <span class="font-mono badge badge-neutral">
                👋
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">The passenger was asked to leave the car</p>
            </div>
          </div>
          <div :if={@trip_values.dropped_off == true} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-neutral">
                Dropped Off
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">The passenger was dropped off</p>
            </div>
          </div>
          <div :if={@trip_values.payment != nil} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-neutral">
                Paid
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Payment was collected</p>
            </div>
          </div>
          <.link
            :if={@embedded}
            navigate={"/trip/#{@trip}?show_details=true"}
            class="absolute bottom-2 right-2 hover:opacity-70 transition-opacity p-2"
          >
            <.icon name="hero-arrows-pointing-out" class="w-6 h-6" />
          </.link>
          <.link
            :if={!@embedded}
            navigate="/"
            class="absolute bottom-2 right-2 hover:opacity-70 transition-opacity p-2"
          >
            <.icon name="hero-arrows-pointing-in" class="w-6 h-6" />
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
