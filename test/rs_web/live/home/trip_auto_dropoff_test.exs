defmodule RsWeb.Live.Home.TripAutoDropoffTest do
  use RsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  require Logger

  @moduletag :integration

  describe "automatic drop-off when customer doesn't show" do
    # Timeout set to 180s because the test waits for simulated GPS updates (max ~85s) plus 60s customer timeout plus buffer
    @tag timeout: 180_000
    test "driver drops off item after waiting 60 seconds for customer at dropoff location", %{
      conn: conn
    } do
      # Step 1: Navigate to homepage and mount LiveView
      {:ok, view, html} = live(conn, "/")

      # Step 2: Verify start trip button exists and is enabled
      assert has_element?(view, "#start-a-new-trip-button-id")
      assert html =~ "Trips in progress"

      # Step 3: Click the start trip button to create a new trip
      Logger.info("Clicking start trip button")
      render_click(view, "on_start_trip_button_click", %{})

      # Step 4: Extract the trip ID from the notification element
      assert has_element?(view, "#new-trip-created-id")

      trip_id =
        view
        |> render()
        |> Floki.parse_document!()
        |> Floki.find("#new-trip-created-id")
        |> Floki.text()
        |> String.trim()

      Logger.info("Extracted trip_id: #{trip_id}")
      assert String.starts_with?(trip_id, "TRIP"), "Expected trip ID to start with 'TRIP'"
      Logger.info("Trip created: #{trip_id}")

      # Step 5: Verify initial state - trip is running
      assert has_element?(view, "#running-status-#{trip_id}-id")
      refute has_element?(view, "#completed-not-delivered-status-#{trip_id}-id")
      refute has_element?(view, "#completed-delivered-status-#{trip_id}-id")

      # Step 6: Wait for driver to reach pickup location
      Logger.info("Waiting for driver #{trip_id} to reach pickup location...")

      pickup_reached =
        poll_for_element(
          view,
          "#waiting-for-food-#{trip_id}-id",
          80_000,
          "waiting for driver #{trip_id} to reach pickup"
        )

      assert pickup_reached, "Driver should reach pickup location within allotted time"
      Logger.info("Driver reached pickup location and is waiting for food")

      # Step 7: Verify "Picked Up" button exists and is enabled
      assert has_element?(view, "#pickup-item-#{trip_id}-button-id")

      pickup_button_html =
        view
        |> element("#pickup-item-#{trip_id}-button-id")
        |> render()

      refute pickup_button_html =~ ~r/disabled\s*=\s*["']disabled["']/,
             "Pickup button should be enabled when driver arrives"

      # Step 8: Click the pickup button (unlike cancellation test, we DO pick up the item)
      trip_view = find_live_child(view, "trip-lv-#{trip_id}")
      Logger.info("Clicking pickup button")
      render_click(trip_view, "on_pickup_item_button_click", %{})

      # Step 9: Wait for driver to reach dropoff location
      Logger.info("Waiting for driver #{trip_id} to reach dropoff location...")

      dropoff_reached =
        poll_for_element(
          view,
          "#waiting-for-customer-#{trip_id}-id",
          85_000,
          "waiting for driver #{trip_id} to reach dropoff"
        )

      assert dropoff_reached, "Driver should reach dropoff location within allotted time"
      Logger.info("Driver reached dropoff location and is waiting for customer")

      # Step 10: Verify the "Waiting for Customer" badge is visible
      assert has_element?(view, "#waiting-for-customer-#{trip_id}-id")

      waiting_customer_badge_html =
        view
        |> element("#waiting-for-customer-#{trip_id}-id")
        |> render()

      assert waiting_customer_badge_html =~ "Waiting for Customer"
      assert waiting_customer_badge_html =~ "⌛️"

      # Step 11: Verify "Handed Off" button exists and is enabled
      assert has_element?(view, "#drop-off-item-#{trip_id}-button-id")

      handoff_button_html =
        view
        |> element("#drop-off-item-#{trip_id}-button-id")
        |> render()

      refute handoff_button_html =~ ~r/disabled\s*=\s*["']disabled["']/,
             "Handoff button should be enabled when driver arrives at dropoff"

      # Step 12: DON'T click the handoff button - let the timer expire
      Logger.info("Waiting for 60+ second customer timeout (not clicking handoff button)...")

      # Step 13: Poll for automatic drop-off
      # The waiting_for_customer_timer is 60 seconds, give it some buffer
      dropoff_occurred =
        poll_for_element(
          view,
          "#dropped-off-#{trip_id}-id",
          85_000,
          "waiting for 60 second customer timeout and auto drop-off"
        )

      assert dropoff_occurred, "Item should be automatically dropped off after 60+ seconds"
      Logger.info("Automatic drop-off occurred")

      # Step 14: Verify the dropped-off badge is visible
      assert has_element?(view, "#dropped-off-#{trip_id}-id")

      dropped_off_badge_html =
        view
        |> element("#dropped-off-#{trip_id}-id")
        |> render()

      assert dropped_off_badge_html =~ "🏠", "Should show house emoji for drop-off"

      # Step 15: Verify payment badge appears (payment should process even for drop-off)
      assert has_element?(view, "#payment-#{trip_id}-id"),
             "Payment should be processed for dropped-off delivery"

      payment_badge_html =
        view
        |> element("#payment-#{trip_id}-id")
        |> render()

      assert payment_badge_html =~ "$"

      # Step 16: Verify final completion state
      # Should show completed-delivered status (trip completed WITH payment)
      assert has_element?(view, "#completed-delivered-status-#{trip_id}-id"),
             "Trip should show as delivered (with payment) even when auto-dropped"

      refute has_element?(view, "#running-status-#{trip_id}-id")
      refute has_element?(view, "#completed-not-delivered-status-#{trip_id}-id")

      # Verify the ✅ icon appears (successful delivery, just dropped off instead of handed off)
      completion_html =
        view
        |> element("#completed-delivered-status-#{trip_id}-id")
        |> render()

      assert completion_html =~ "✅"

      # Step 17: Verify handed-off badge is NOT present (should only have dropped-off)
      refute has_element?(view, "#handed-off-#{trip_id}-id"),
             "Should not show handed-off badge for auto drop-off"

      Logger.info("Test completed successfully - trip #{trip_id} completed with automatic drop-off and payment")
    end
  end

  # Helper: Poll for an element to appear within a timeout period
  # Returns true if element appears, false if timeout is reached
  defp poll_for_element(view, element_id, timeout_ms, description) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_for_element_until(view, element_id, deadline, description)
  end

  defp poll_for_element_until(view, element_id, deadline, description) do
    now = System.monotonic_time(:millisecond)

    if now >= deadline do
      Logger.warning("Timeout reached while #{description}")
      false
    else
      # Trigger a render to get latest state from the LiveView
      render(view)

      if has_element?(view, element_id) do
        true
      else
        # Poll every 500ms
        Process.sleep(500)
        poll_for_element_until(view, element_id, deadline, description)
      end
    end
  end
end
