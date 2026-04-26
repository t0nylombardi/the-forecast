require "test_helper"

module Weather
  class ForecastServiceTest < ActiveSupport::TestCase
    test ".call returns an empty hash when location and postal code are blank" do
      assert_equal({}, ForecastService.call(location: nil, postal_code: nil))
    end

    test "#call returns cached data without hitting the API" do
      service = ForecastService.new(location: "Brooklyn", postal_code: "11201")
      api_client = Object.new
      geocoder = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { { "temp" => 67 } }
      geocoder.define_singleton_method(:call) do |_postal_code|
        flunk "expected cache hit to skip geocoder call"
      end
      api_client.define_singleton_method(:fetch_forecast) do |**_kwargs|
        flunk "expected cache hit to skip API call"
      end

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@geocoder, geocoder)
      service.instance_variable_set(:@api_client, api_client)

      assert_equal({ "temp" => 67 }, service.call)
    end

    test "#call geocodes the ZIP, fetches forecast data, and writes to cache" do
      service = ForecastService.new(location: "Brooklyn", postal_code: "11201")
      geocoder = Object.new
      api_client = Object.new
      cache = Object.new
      written = nil
      requested_postal_code = nil
      requested_coordinates = nil
      forecast = { "current" => { "temp" => 64 }, "daily" => [] }

      cache.define_singleton_method(:read) { nil }
      cache.define_singleton_method(:write) { |data| written = data }
      geocoder.define_singleton_method(:call) do |postal_code|
        requested_postal_code = postal_code
        { lat: 40.695, lon: -73.989 }
      end
      api_client.define_singleton_method(:fetch_forecast) do |lat:, lon:|
        requested_coordinates = [lat, lon]
        forecast
      end

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@geocoder, geocoder)
      service.instance_variable_set(:@api_client, api_client)

      result = service.call

      assert_equal "11201", requested_postal_code
      assert_equal [40.695, -73.989], requested_coordinates
      assert_equal 64, result.dig("current", "temp")
      assert_equal result, written
    end

    test "#call wraps geocoder errors" do
      service = ForecastService.new(location: "Chicago")
      geocoder = Object.new
      api_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      geocoder.define_singleton_method(:call) { |_postal_code| raise Geocoder::Error, "ZIP not found" }
      api_client.define_singleton_method(:fetch_forecast) { |**_kwargs| flunk "expected geocoder failure to short-circuit" }

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@geocoder, geocoder)
      service.instance_variable_set(:@api_client, api_client)

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "ZIP not found", error.message
    end

    test "#call wraps forecast client errors" do
      service = ForecastService.new(location: "Seattle")
      geocoder = Object.new
      api_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      geocoder.define_singleton_method(:call) { |_postal_code| { lat: 47.6062, lon: -122.3321 } }
      api_client.define_singleton_method(:fetch_forecast) do |**_kwargs|
        raise ApiClient::Error, "Weather API request failed"
      end

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@geocoder, geocoder)
      service.instance_variable_set(:@api_client, api_client)

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "Weather API request failed", error.message
    end
  end
end
