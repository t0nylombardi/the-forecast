require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get forecasts_url

    assert_response :success
    assert_select "h1", "Forecasts"
    assert_select "form[action='#{update_forecast_forecasts_path}']"
  end

  test "update_forecast renders forecast details for turbo stream requests" do
    forecast_payload = {
      "location" => {"name" => "New York", "region" => "NY"},
      "current" => {
        "temp_f" => 72,
        "condition" => {"text" => "Sunny"}
      }
    }
    received_arguments = nil

    stub_singleton_method(Weather::ForecastService, :call, ->(location:, zip_code:) {
      received_arguments = [location, zip_code]
      forecast_payload
    }) do
      patch update_forecast_forecasts_url,
        params: {location: "New York", postal_code: "10001"},
        as: :turbo_stream
    end

    assert_equal ["New York", "10001"], received_arguments
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
    assert_includes response.body, "New York"
    assert_includes response.body, "72F"
  end

  test "update_forecast shows the service error for turbo stream requests" do
    error_payload = {"error" => {"message" => "Location not found"}}
    received_arguments = nil

    stub_singleton_method(Weather::ForecastService, :call, ->(location:, zip_code:) {
      received_arguments = [location, zip_code]
      error_payload
    }) do
      patch update_forecast_forecasts_url,
        params: {location: "Atlantis"},
        as: :turbo_stream
    end

    assert_equal ["Atlantis", nil], received_arguments
    assert_response :unprocessable_entity
    assert_includes response.body, "Location not found"
  end
end
