defmodule RsWeb.Live.Components.Analytics do
  use RsWeb, :html
  import RsWeb.Live.Classes

  @moduledoc false

  def render(assigns) do
    ~H"""
    <div id="trips-summary-analytics-id" class="mx-auto max-w-2xl flex justify-center px-3">
      <div class="text-sm font-mono border-1 rounded-md mt-3 p-4 bg-base-100 w-full">
        <div class="py-1">
          <div>
            JourDash Deliveries
          </div>
          <div id="deliveries-analytics-id" class="font-mono py-2">
            <div class="">
              <span :if={@trip_count_in_progress > 0} class="status status-success animate-pulse"></span>
              <span :if={@trip_count_in_progress <= 0} class="">●</span>
              in progress: <span class="font-mono badge badge-info">{@trip_count_in_progress}</span>
            </div>
            <div class="">
              ● completed: <span class="font-mono badge badge-info">{@trip_count_completed}</span>
            </div>
            <div id="completed-details-analytics-id" class="">
              <div class="ml-2">
                <span class="font-mono">{@trip_count_food_no_show}</span>
                /
                <span id="food-no-show-percentage-id" class="font-mono">
                  {percentage(@trip_count_food_no_show, @trip_count_completed)}
                </span>
                – {no_show()} food no show
              </div>
              <div class="ml-2">
                <span class="font-mono">{@trip_count_dropped_off}</span>
                /
                <span id="dropped-off-percentage-id" class="font-mono">
                  {percentage(@trip_count_dropped_off, @trip_count_completed)}
                </span>
                – {dropped_off()} dropped off
              </div>
              <div class="ml-2">
                <span class="font-mono">{@trip_count_handed_off}</span>
                /
                <span id="handed-off-percentage-id" class="font-mono">
                  {percentage(@trip_count_handed_off, @trip_count_completed)}
                </span>
                – {handed_off()} handed off
              </div>
            </div>
            <div class="">
              ● paid:
              <span class="font-mono badge badge-info">
                {@trip_count_paid}
              </span>
              / <span class="font-mono">{percentage(@trip_count_paid, @trip_count_completed)}</span>
            </div>
          </div>
        </div>
        <div class="pt-2 text-center">
          <div
            id="form-show-analytics-id"
            phx-click="on-toggle-view-analytics-click"
            class="hover:bg-info p-2 rounded-md"
          >
            <.icon
              :if={not @view_analytics}
              name="hero-chevron-down"
              class="w-4 h-4 p-1 "
            />
            <.icon
              :if={@view_analytics}
              name="hero-chevron-up"
              class="w-4 h-4 p-1"
            /> Detailed Analytics
            <.icon
              :if={not @view_analytics}
              name="hero-chevron-down"
              class="w-4 h-4 p-1 "
            />
            <.icon
              :if={@view_analytics}
              name="hero-chevron-up"
              class="w-4 h-4 p-1"
            />
          </div>
        </div>

        <div :if={@view_analytics}>
          <div class="text-sm font-mono bg-base-100 w-full p-1">(refreshed on page reload)</div>
          <pre
            :if={@view_analytics}
            id="analytics-id"
            class="border-1 p-3 bg-neutral rounded-md my-2 whitespace-pre-wrap break-words"
          >{@analytics}</pre>
        </div>
      </div>
    </div>
    """
  end

  defp percentage(numerator, denominator) do
    if denominator > 0 do
      "#{round(numerator / denominator * 100)}%"
    else
      "N/A"
    end
  end
end
