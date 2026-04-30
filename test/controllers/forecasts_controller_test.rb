require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    received_ip = nil
    received_postal_code = nil
    payload = forecast_payload(postal_code: "10001", city: "New York")

    stub_singleton_method(Location::IpLookupService, :call, ->(ip_address:) {
      received_ip = ip_address
      "10001"
    }) do
      stub_singleton_method(Weather::ForecastService, :call, ->(postal_code:) {
        received_postal_code = postal_code
        payload
      }) do
        get forecasts_url
      end
    end

    assert received_ip.present?
    assert_equal "10001", received_postal_code
    assert_response :success
    assert_select ".forecast-hero__title", "New York, US"
    assert_select "form[action='#{update_forecast_forecasts_path}']"
  end

  test "update_forecast renders forecast details for turbo stream requests" do
    received_postal_code = nil
    payload = forecast_payload(postal_code: "10001", city: "New York", temperature: 72, description: "Sunny")

    stub_singleton_method(Weather::ForecastService, :call, ->(postal_code:) {
      received_postal_code = postal_code
      payload
    }) do
      patch update_forecast_forecasts_url,
        params: {forecast: {postal_code: "10001"}},
        as: :turbo_stream
    end

    assert_equal "10001", received_postal_code
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
    assert_includes response.body, "New York"
    assert_includes response.body, "72°"
  end

  test "update_forecast renders forecast details for html requests" do
    received_postal_code = nil
    payload = forecast_payload(postal_code: "10590", city: "South Salem", temperature: 61, description: "Cloudy")

    stub_singleton_method(Weather::ForecastService, :call, ->(postal_code:) {
      received_postal_code = postal_code
      payload
    }) do
      patch update_forecast_forecasts_url,
        params: {forecast: {postal_code: "10590"}}
    end

    assert_equal "10590", received_postal_code
    assert_response :success
    assert_includes response.body, "South Salem"
    assert_includes response.body, "61°"
  end

  test "update_forecast shows the service error for turbo stream requests" do
    received_postal_code = nil

    stub_singleton_method(Weather::ForecastService, :call, ->(postal_code:) {
      received_postal_code = postal_code
      raise Weather::ForecastService::Failure, "ZIP not found"
    }) do
      patch update_forecast_forecasts_url,
        params: {forecast: {postal_code: "00000"}},
        as: :turbo_stream
    end

    assert_equal "00000", received_postal_code
    assert_response :unprocessable_entity
    assert_includes response.body, "ZIP not found"
  end

  private

  def forecast_payload(postal_code:, city:, temperature: 68, description: "Light rain")
    {
      data: {
        location: {
          name: city,
          country: "US",
          postal_code: postal_code
        },
        current: {
          time: Time.zone.local(2026, 4, 30, 8, 45),
          temperature: temperature,
          description: description
        },
        daily: 7.times.map do |index|
          {
            date: Date.new(2026, 4, 30) + index.days,
            description: description,
            high: temperature + index,
            low: temperature - 8 + index
          }
        end
      },
      cache: {hit: false}
    }
  end
end
