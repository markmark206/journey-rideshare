defmodule RsWeb.Live.Home.TripCancellationTest do
  use RsWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  require Logger

  @moduletag :integration

  describe "trip cancellation flow when driver waits for food" do
    @tag timeout: 120_000
    test "driver cancels trip after waiting 60 seconds for food at pickup location", %{
      conn: conn
    } do
      # Step 1: Navigate to homepage and mount LiveView
      {:ok, view, html} = live(conn, "/")

      # Step 2: Verify start trip button exists and is enabled
      assert has_element?(view, "#start-a-new-trip-button-id")
      assert html =~ "Deliveries"

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
          120_000,
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

      # Step 9: DON'T click the pickup button - let the timer expire
      Logger.info("Waiting for 60+ second timeout (not clicking pickup button)...")

      # Step 10: Poll for trip cancellation
      # The waiting_for_food_at_restaurant_timer is 60 seconds, give it some buffer
      timeout_occurred =
        poll_for_element(
          view,
          "#no-food-timeout-#{trip_id}-id",
          70_000,
          "waiting for 60 second timeout"
        )

      assert timeout_occurred, "Trip should show timeout indicator after 60+ seconds"
      Logger.info("Timeout occurred - trip should be cancelled")

      # Step 11: Verify final completion state
      # Should show completed-not-delivered status (trip completed but no payment)
      assert has_element?(view, "#completed-not-delivered-status-#{trip_id}-id")
      refute has_element?(view, "#running-status-#{trip_id}-id")
      refute has_element?(view, "#completed-delivered-status-#{trip_id}-id")

      # Verify the ❌ icon appears in the completion status
      completion_html =
        view
        |> element("#completed-not-delivered-status-#{trip_id}-id")
        |> render()

      assert completion_html =~ "❌"

      # Verify the timeout badge is present
      assert has_element?(view, "#no-food-timeout-#{trip_id}-id")

      timeout_badge_html =
        view
        |> element("#no-food-timeout-#{trip_id}-id")
        |> render()

      assert timeout_badge_html =~ "No Food"

      Logger.info("Test completed successfully - trip #{trip_id} was cancelled as expected")
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
