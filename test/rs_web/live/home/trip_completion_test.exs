defmodule RsWeb.Live.Home.TripCompletionTest do
  use RsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  require Logger

  @moduletag :integration

  describe "successful trip completion flow" do
    # Timeout set to 150s to account for Journey's 6-25s random startup delay
    # Worst case: 25s startup + 15 units × 5s = ~100s plus verification buffer
    @tag timeout: 150_000
    test "driver completes trip with pickup and handoff to customer", %{conn: conn} do
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
      Logger.info("Looking for element: #waiting-for-food-#{trip_id}-id")

      pickup_reached =
        poll_for_element(
          view,
          "#waiting-for-food-#{trip_id}-id",
          100_000,
          "waiting for driver #{trip_id} to reach pickup"
        )

      assert pickup_reached, "Driver should reach pickup location within allotted time"
      Logger.info("Driver reached pickup location and is waiting for food")

      # Step 7: Verify the "Waiting for Food" badge is visible
      assert has_element?(view, "#waiting-for-food-#{trip_id}-id")

      waiting_badge_html =
        view
        |> element("#waiting-for-food-#{trip_id}-id")
        |> render()

      assert waiting_badge_html =~ "Waiting for Food"
      assert waiting_badge_html =~ "⌛️"

      # Step 8: Verify "Picked Up" button exists and is enabled
      assert has_element?(view, "#pickup-item-#{trip_id}-button-id")

      # Check that the button is NOT disabled
      pickup_button_html =
        view
        |> element("#pickup-item-#{trip_id}-button-id")
        |> render()

      refute pickup_button_html =~ ~r/disabled\s*=\s*["']disabled["']/,
             "Pickup button should be enabled when driver arrives"

      # Step 9: Click the pickup button to simulate driver picking up the food
      # Find the child LiveView for this specific trip
      trip_view = find_live_child(view, "trip-lv-#{trip_id}")

      Logger.info("Clicking pickup button")
      render_click(trip_view, "on_pickup_item_button_click", %{})

      # Step 10: Verify the pickup button is now disabled and shows checkmark
      Process.sleep(200)
      render(view)

      pickup_button_html_after =
        view
        |> element("#pickup-item-#{trip_id}-button-id")
        |> render()

      assert pickup_button_html_after =~ "✅"

      # Step 11: Wait for driver to reach dropoff location
      Logger.info("Waiting for driver #{trip_id} to reach dropoff location...")
      Logger.info("Looking for element: #waiting-for-customer-#{trip_id}-id")

      dropoff_reached =
        poll_for_element(
          view,
          "#waiting-for-customer-#{trip_id}-id",
          100_000,
          "waiting for driver #{trip_id} to reach dropoff"
        )

      assert dropoff_reached, "Driver should reach dropoff location within allotted time"
      Logger.info("Driver reached dropoff location and is waiting for customer")

      # Step 12: Verify the "Waiting for Customer" badge is visible
      assert has_element?(view, "#waiting-for-customer-#{trip_id}-id")

      waiting_customer_badge_html =
        view
        |> element("#waiting-for-customer-#{trip_id}-id")
        |> render()

      assert waiting_customer_badge_html =~ "Waiting for Customer"
      assert waiting_customer_badge_html =~ "⌛️"

      # Step 13: Verify "Handed Off" button exists and is enabled
      assert has_element?(view, "#drop-off-item-#{trip_id}-button-id")

      handoff_button_html =
        view
        |> element("#drop-off-item-#{trip_id}-button-id")
        |> render()

      refute handoff_button_html =~ ~r/disabled\s*=\s*["']disabled["']/,
             "Handoff button should be enabled when driver arrives at dropoff"

      # Step 14: Click the handoff button to complete the delivery
      Logger.info("Clicking handoff button")
      render_click(trip_view, "on_handoff_item_button_click", %{})

      # Step 15: Wait for payment processing and trip completion
      Logger.info("Waiting for payment processing...")

      payment_processed =
        poll_for_element(
          view,
          "#payment-#{trip_id}-id",
          5_000,
          "waiting for payment to process"
        )

      assert payment_processed, "Payment should be processed within allotted time"
      Logger.info("Payment processed successfully")

      # Step 16: Verify the payment badge is visible
      assert has_element?(view, "#payment-#{trip_id}-id")

      payment_badge_html =
        view
        |> element("#payment-#{trip_id}-id")
        |> render()

      assert payment_badge_html =~ "$"

      # Step 17: Verify the handed off badge is visible
      assert has_element?(view, "#handed-off-#{trip_id}-id")

      handed_off_badge_html =
        view
        |> element("#handed-off-#{trip_id}-id")
        |> render()

      assert handed_off_badge_html =~ "🧑‍🦱"

      # Step 18: Verify final completion state
      # Should show completed-delivered status (trip completed WITH payment)
      assert has_element?(view, "#completed-delivered-status-#{trip_id}-id")
      refute has_element?(view, "#running-status-#{trip_id}-id")
      refute has_element?(view, "#completed-not-delivered-status-#{trip_id}-id")

      # Verify the ✅ icon appears in the completion status
      completion_html =
        view
        |> element("#completed-delivered-status-#{trip_id}-id")
        |> render()

      assert completion_html =~ "✅"

      Logger.info("Test completed successfully - trip #{trip_id} completed with successful delivery")
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
