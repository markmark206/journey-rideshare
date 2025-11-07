defmodule RsWeb.Live.Components.TripCard do
  use RsWeb, :html
  require Logger
  import RsWeb.Live.Classes

  import RS.Helpers

  @moduledoc false

  defp format_time_ago(seconds) do
    cond do
      seconds < 60 -> "#{seconds}s"
      seconds < 3600 -> "#{div(seconds, 60)}m"
      seconds < 86_400 -> "#{div(seconds, 3600)}h"
      seconds < 604_800 -> "#{div(seconds, 86_400)}d"
      true -> "#{div(seconds, 604_800)}w"
    end
  end

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
            <span class="font-mono badge badge-info">in progress</span>
            <span class="font-mono status status-info status-md animate-pulse"></span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment != nil}
            class="ml-auto flex items-center gap-2"
          >
            <span>completed</span><span class="font-mono badge badge-neutral">{format_time_ago(@last_updated_seconds_ago)}</span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment == nil}
            class="ml-auto flex items-center gap-2"
          >
            <span>completed</span><span class="font-mono badge badge-neutral">{format_time_ago(@last_updated_seconds_ago)}</span>
          </span>
        </h1>
        <div id="locations-destinations-id" class="text-xs font-mono">
          <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
            <% marker =
              cond do
                i == @trip_values.location_pickup and @trip_values.waiting_for_food_at_restaurant_timeout != nil ->
                  @trip_values.item_to_deliver

                i == @trip_values.location_pickup and @trip_values.picked_up == true ->
                  "🧑🏼‍🍳"

                i == @trip_values.location_pickup and @trip_values.picked_up != true ->
                  @trip_values.item_to_deliver

                i == @trip_values.location_dropoff and (@trip_values.dropped_off == true or @trip_values.handed_off == true) ->
                  @trip_values.item_to_deliver

                i == @trip_values.location_dropoff and @trip_values.dropped_off != true and @trip_values.handed_off != true ->
                  "🏠"

                true ->
                  "."
              end %>
            <span class="font-mono">{marker}</span>
          <% end %>
        </div>
        <div id="locations-driver-id" class="text-xs font-mono">
          <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
            <%= cond do %>
              <% i == @trip_values.location_driver and @trip_values.trip_completed_at == nil and i >= @trip_values.location_pickup and @trip_values.picked_up -> %>
                <span class="font-mono animate-pulse">{@trip_values.item_to_deliver}</span>
              <% i == @trip_values.location_pickup and @trip_values.picked_up -> %>
                <span class="font-mono">✅</span>
              <% i == @trip_values.location_driver and @trip_values.trip_completed_at == nil -> %>
                <span class="font-mono animate-pulse">🚗</span>
              <% i == @trip_values.location_pickup and @trip_values.waiting_for_food_at_restaurant_timeout != nil -> %>
                <span class="font-mono">⌛️</span>
              <% i == @trip_values.location_driver and i == @trip_values.location_dropoff and @trip_values.handed_off -> %>
                <span class="font-mono">✅</span>
              <% i == @trip_values.location_driver and i == @trip_values.location_dropoff and @trip_values.dropped_off -> %>
                <span class="font-mono">📦</span>
              <% i <= @trip_values.location_driver -> %>
                <span class="font-mono">_</span>
              <% true  -> %>
                <span class="font-mono">.</span>
            <% end %>
          <% end %>
        </div>
        <div class="mt-1 pt-1">
          <.button
            disabled={
              @trip_values.picked_up == true or @trip_values.waiting_for_food_at_restaurant != true or
                @trip_values.trip_completed_at != nil
            }
            id={"pickup-item-#{@trip}"}
            phx-click="on_pickup_item_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            <span :if={@trip_values.picked_up == true}>✅</span> Picked Up
          </.button>
          <.button
            disabled={
              @trip_values.waiting_for_customer_timer == nil or
                (@trip_values.handed_off == true or @trip_values.dropped_off == true)
            }
            id={"drop-off-item-#{@trip}-id"}
            phx-click="on_handoff_item_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            <span :if={@trip_values.handed_off == true}>✅</span> Handed Off
          </.button>
        </div>

        <div class="font-mono my-1 py-1 text-xs">
          <div class="">
            <span>
              {to_datetime_string!(@trip_values.created_at, @trip_values.started_in_time_zone)}
            </span>
            <span :if={@trip_values.started_in_time_zone != nil} class="">
              ({@trip_values.started_in_time_zone})
            </span>
          </div>
        </div>
        <div class="font-mono my-1 py-1">
          <div class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <span class={[
                "font-mono",
                badge(@trip_values.trip_completed_at == nil)
              ]}>
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
            <label tabindex="0" class={["font-mono", badge(@trip_values.trip_completed_at == nil)]}>
              <span :if={@trip_values.trip_completed_at != nil}>
                <.icon name="hero-clock" class="w-4 h-4" /> {@trip_values.trip_completed_at - @trip_values.created_at}s
              </span>
              <span :if={@trip_values.trip_completed_at == nil}>
                <.icon name="hero-clock" class="w-4 h-4" /> {@trip_values.last_updated_at - @trip_values.created_at}s
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Trip duration</p>
            </div>
          </div>
          <div
            :if={@trip_values.waiting_for_food_at_restaurant == true and @trip_values.trip_completed_at == nil}
            class="font-mono badge badge-info"
          >
            <span class="animate-pulse">⌛️</span> Waiting for Food
          </div>
          <div :if={@trip_values.picked_up == true} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-neutral">
                {@trip_values.item_to_deliver} 🚗
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">The order was picked up</p>
            </div>
          </div>

          <div
            :if={@trip_values.waiting_for_food_at_restaurant_timeout != nil and @trip_values.trip_completed_at != nil}
            class="dropdown dropdown-top inline-block"
          >
            <label tabindex="0">
              <span class="font-mono badge badge-warning">
                No Food
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Food was not provided by restaurant</p>
            </div>
          </div>

          <span
            :if={
              @trip_values.waiting_for_customer_at_dropoff == true and @trip_values.handed_off != true and
                @trip_values.dropped_off != true
            }
            class="font-mono badge badge-info"
          >
            <span class="animate-pulse">⌛️</span> Waiting for Customer
          </span>
          <div
            :if={@trip_values.dropped_off == true}
            class="dropdown dropdown-top inline-block"
          >
            <label tabindex="0">
              <span class="font-mono badge badge-neutral">
                {@trip_values.item_to_deliver} 🏠
              </span>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">The customer did not come out, food dropped off</p>
            </div>
          </div>
          <div
            :if={@trip_values.handed_off == true}
            class="dropdown dropdown-top inline-block"
          >
            <label tabindex="0">
              <div class="font-mono badge badge-neutral">
                {@trip_values.item_to_deliver} 🧑‍🦱
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Handed the food off to the customer</p>
            </div>
          </div>
          <div :if={@trip_values.payment != nil} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-success">
                ${@trip_values.price_cents / 100}
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
