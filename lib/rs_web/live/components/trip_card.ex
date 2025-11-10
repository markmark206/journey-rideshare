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
        id={"trip-card-inner-container-#{@trip}-id"}
        class={
          [section2_no_margin(), "relative"] ++
            if @trip_values.trip_completed_at != nil, do: ["text-secondary-content/40"], else: [""]
        }
      >
        <h1 class="mb-2 pb-2 flex items-center">
          <span>
            <span class={data_point()}>{@trip}</span>
          </span>
          <span
            :if={@trip_values.trip_completed_at == nil}
            id={"running-status-#{@trip}-id"}
            class="ml-auto flex items-center gap-2"
          >
            <span class="font-mono badge badge-neutral p-1 badge-lg">
              <span>{@trip_values.item_to_deliver}</span>
              <span class="status status-success mx-1 status-lg animate-pulse"></span>
            </span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment != nil}
            id={"completed-delivered-status-#{@trip}-id"}
            class="ml-auto flex items-center gap-2"
          >
            <span class="font-mono badge badge-neutral badge-lg">
              <span>{@trip_values.item_to_deliver}</span>
              <span>✅</span>
              <span>{format_time_ago(@last_updated_seconds_ago)} ago</span>
            </span>
          </span>
          <span
            :if={@trip_values.trip_completed_at != nil and @trip_values.payment == nil}
            class="ml-auto flex items-center gap-2"
            id={"completed-not-delivered-status-#{@trip}-id"}
          >
            <span class="font-mono badge badge-neutral badge-lg">
              <span>{@trip_values.item_to_deliver}</span>
              <span>❌</span>
              <span>{format_time_ago(@last_updated_seconds_ago)} ago</span>
            </span>
          </span>
        </h1>
        <div id={"trip-journey-container-#{@trip}-id"} class="font-mono my-1 py-2">
          <div id={"locations-destinations-#{@trip}-id"} class="text-sm font-mono">
            <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
              <%= cond do %>
                <% i == @trip_values.location_pickup and @trip_values.waiting_for_food_at_restaurant_timeout != nil -> %>
                  <span class="font-mono text-lg">{@trip_values.item_to_deliver}</span>
                <% i == @trip_values.location_pickup and @trip_values.picked_up == true -> %>
                  <span class="font-mono text-lg">🧑🏼‍🍳</span>
                <% i == @trip_values.location_pickup and @trip_values.picked_up != true -> %>
                  <span class="font-mono text-lg">{@trip_values.item_to_deliver}</span>
                <% i == @trip_values.location_dropoff and (@trip_values.dropped_off == true or @trip_values.handed_off == true) -> %>
                  <span class="font-mono text-lg">{@trip_values.item_to_deliver}</span>
                <% i == @trip_values.location_dropoff and @trip_values.dropped_off != true and @trip_values.handed_off != true -> %>
                  <span class="font-mono text-lg">🏠</span>
                <% true -> %>
                  <span class="font-mono">&nbsp;</span>
              <% end %>
            <% end %>
          </div>
          <div id={"locations-driver-#{@trip}-id"} class="text-sm font-mono ">
            <%= for i <- @trip_values.location_driver_initial..@trip_values.location_dropoff do %>
              <%= cond do %>
                <% i == @trip_values.location_driver and @trip_values.trip_completed_at == nil and i >= @trip_values.location_pickup and @trip_values.picked_up -> %>
                  <span class="font-mono animate-pulse text-lg">{@trip_values.item_to_deliver}</span>
                <% i == @trip_values.location_pickup and @trip_values.picked_up -> %>
                  <span class="font-mono text-lg">✅</span>
                <% i == @trip_values.location_driver and @trip_values.trip_completed_at == nil -> %>
                  <span class="font-mono text-lg animate-pulse inline-block -scale-x-100">🚗</span>
                <% i == @trip_values.location_pickup and @trip_values.waiting_for_food_at_restaurant_timeout != nil -> %>
                  <span class="font-mono text-lg">⌛️</span>
                <% i == @trip_values.location_driver and i == @trip_values.location_dropoff and @trip_values.handed_off -> %>
                  <span class="font-mono text-lg">✅</span>
                <% i == @trip_values.location_driver and i == @trip_values.location_dropoff and @trip_values.dropped_off -> %>
                  <span class="font-mono text-lg">📦</span>
                <% i <= @trip_values.location_driver -> %>
                  <span class="font-mono text-success">_</span>
                <% true  -> %>
                  <span class="font-mono">.</span>
              <% end %>
            <% end %>
          </div>
        </div>
        <div class="mt-1 pt-1">
          <.button
            id={"pickup-item-#{@trip}-button-id"}
            disabled={
              @trip_values.picked_up == true or @trip_values.waiting_for_food_at_restaurant != true or
                @trip_values.trip_completed_at != nil
            }
            phx-click="on_pickup_item_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            <span :if={@trip_values.picked_up == true}>✅</span> Picked Up
          </.button>
          <.button
            id={"drop-off-item-#{@trip}-button-id"}
            disabled={
              @trip_values.waiting_for_customer_timer == nil or
                (@trip_values.handed_off == true or @trip_values.dropped_off == true)
            }
            phx-click="on_handoff_item_button_click"
            phx-value-trip={@trip}
            class="btn btn-sm btn-primary my-2 py-2"
          >
            <span :if={@trip_values.handed_off == true}>✅</span> Handed Off
          </.button>
        </div>

        <div :if={false} id={"created-at-#{@trip}-id"} class="font-mono my-1 py-1 text-xs">
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
            id={"waiting-for-food-#{@trip}-id"}
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
            id={"no-food-timeout-#{@trip}-id"}
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
            id={"waiting-for-customer-#{@trip}-id"}
            class="font-mono badge badge-info"
          >
            <span class="animate-pulse">⌛️</span> Waiting for Customer
          </span>
          <div
            :if={@trip_values.dropped_off == true}
            id={"dropped-off-#{@trip}-id"}
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
            id={"handed-off-#{@trip}-id"}
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
          <div :if={@trip_values.payment != nil} id={"payment-#{@trip}-id"} class="dropdown dropdown-top inline-block">
            <label tabindex="0">
              <div class="font-mono badge badge-success">
                ${@trip_values.price_cents / 100}
              </div>
            </label>
            <div tabindex="0" class="dropdown-content z-[1] p-3 shadow bg-base-200 rounded-box mb-1 min-w-[200px]">
              <p class="text-sm">Payment was collected</p>
            </div>
          </div>

          <div :if={@expanded?} class={card_section()}>
            <div class={list_element()}>Driver: <span class={data_point_no_border()}>{@trip_values.driver_id}</span></div>
            <div class={list_element()}>
              Started in Time Zone: <span class={data_point_no_border()}>{@trip_values.started_in_time_zone}</span>
            </div>
            <div class={list_element()}>
              Order: <span class={data_point_no_border()}>{@trip_values.order_id}</span>
            </div>
            <div class={list_element()}>
              Starting point: <span class={data_point_no_border()}>{@trip_values.location_driver_initial}</span>
            </div>
            <div class={list_element()}>
              Pickup point: <span class={data_point_no_border()}>{@trip_values.location_pickup}</span>
            </div>
            <div class={list_element()}>
              Dropoff point: <span class={data_point_no_border()}>{@trip_values.location_dropoff}</span>
            </div>
            <div class={list_element()}>
              Price: <span class={data_point_no_border()}>${@trip_values.price_cents / 100}</span>
            </div>
          </div>

          <div :if={@trip_values.trip_history != nil and @expanded?} class={card_section()}>
            History:
            <%= for %{"node" => node, "timestamp" => timestamp, "value" => value} <- @trip_values.trip_history |> Enum.reverse() do %>
              <div class="text-xs my-1 font-mono">
                <span class="text-info">{to_datetime_string_compact(timestamp, @trip_values.started_in_time_zone)}:</span> {node}
                <span class="text-info">{value}</span>
              </div>
            <% end %>
          </div>

          <div
            :if={!@embedded? and @trip_values != nil and @expanded?}
            id={"trip-raw-trip-values-#{@trip}-id"}
            class={card_section()}
          >
            Raw Trip Values:
            <div class="text-xs my-1 font-mono">
              <pre class="whitespace-pre-wrap break-words">{"#{inspect(@trip_values, pretty: true)}"}</pre>
            </div>
          </div>

          <div
            :if={@expanded?}
            id={"trip-card-page-link-#{@trip}-id"}
            class="absolute bottom-2 left-2 hover:opacity-70 transition-opacity p-2"
          >
            <.link
              :if={@embedded?}
              navigate={"/trip/#{@trip}"}
              class="hover:opacity-70 transition-opacity"
            >
              .
            </.link>

            <.link
              :if={!@embedded?}
              navigate="/"
              class="hover:opacity-70 transition-opacity"
            >
              .
            </.link>
          </div>
          <div
            id={"trip-card-chevron-down-#{@trip}-id"}
            phx-click="on_trip_card_chevron_down_click"
            class="absolute bottom-2 right-2 hover:opacity-70 transition-opacity p-2"
          >
            <.icon :if={!@expanded?} name="hero-chevron-down" class="w-6 h-6" />
            <.icon :if={@expanded?} name="hero-chevron-up" class="w-6 h-6" />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
