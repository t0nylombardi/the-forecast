require "test_helper"

module Weather
  class ForecastServiceTest < ActiveSupport::TestCase
    test ".call raises when postal code is blank" do
      error = assert_raises(ForecastService::Failure) { ForecastService.call(postal_code: nil) }

      assert_equal "Postal code is required", error.message
    end

    test "#call returns cached data without hitting collaborators" do
      geocoder = Object.new
      forecast_client = Object.new
      normalizer = Object.new
      cache = Object.new
      cached_payload = {data: {current: {temperature: 67}}, cache: {hit: true}}

      cache.define_singleton_method(:read) { cached_payload }
      geocoder.define_singleton_method(:call) { |_postal_code| flunk "expected cache hit to skip geocoder" }
      forecast_client.define_singleton_method(:fetch_forecast) { |**_kwargs| flunk "expected cache hit to skip forecast client" }
      normalizer.define_singleton_method(:call) { |_data| flunk "expected cache hit to skip normalizer" }

      service = ForecastService.new(
        postal_code: "11201",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: normalizer,
        cache: cache
      )

      assert_equal cached_payload, service.call
    end

    test "#call geocodes, fetches, normalizes, and caches the forecast" do
      geocoder = Object.new
      forecast_client = Object.new
      normalizer = Object.new
      cache = Object.new
      requested_postal_code = nil
      requested_coordinates = nil
      raw_forecast = {"current" => {"temp" => 64}}
      normalized_forecast = {current: {temperature: 64}}
      written_payload = {data: normalized_forecast, cache: {hit: false}}

      cache.define_singleton_method(:read) { nil }
      cache.define_singleton_method(:write) { |data| (data == normalized_forecast) ? written_payload : flunk("unexpected cache write") }
      geocoder.define_singleton_method(:call) do |postal_code|
        requested_postal_code = postal_code
        {lat: 40.695, lon: -73.989}
      end
      forecast_client.define_singleton_method(:fetch_forecast) do |lat:, lon:|
        requested_coordinates = [lat, lon]
        raw_forecast
      end
      normalizer.define_singleton_method(:call) { |data| (data == raw_forecast) ? normalized_forecast : flunk("unexpected normalizer input") }

      service = ForecastService.new(
        postal_code: "11201",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: normalizer,
        cache: cache
      )

      result = service.call

      assert_equal "11201", requested_postal_code
      assert_equal [40.695, -73.989], requested_coordinates
      assert_equal written_payload, result
    end

    test "#call wraps geocoder errors" do
      geocoder = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      geocoder.define_singleton_method(:call) { |_postal_code| raise Geocoder::Error, "ZIP not found" }

      service = ForecastService.new(
        postal_code: "00000",
        geocoder: geocoder,
        forecast_client: ForecastClient.new,
        normalizer: ForecastNormalizer,
        cache: cache
      )

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "ZIP not found", error.message
    end

    test "#call wraps forecast client errors" do
      geocoder = Object.new
      forecast_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      geocoder.define_singleton_method(:call) { |_postal_code| {lat: 47.6062, lon: -122.3321} }
      forecast_client.define_singleton_method(:fetch_forecast) do |**_kwargs|
        raise ApiClient::Error, "Weather API request failed"
      end

      service = ForecastService.new(
        postal_code: "98101",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: ForecastNormalizer,
        cache: cache
      )

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "Weather API request failed", error.message
    end
  end
end
