require "test_helper"

module Weather
  class ForecastServiceTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test ".call returns an empty hash when location is nil" do
      assert_equal({}, ForecastService.call(location: nil))
    end

    test "#call returns cached data without hitting the API" do
      service = ForecastService.new(location: "Brooklyn", postal_code: "11201")
      api_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { { "temp" => 67 } }
      api_client.define_singleton_method(:fetch_forecast) do |_location|
        flunk "expected cache hit to skip API call"
      end

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@api_client, api_client)

      assert_equal({ "temp" => 67 }, service.call)
    end

    test "#call fetches from the API and writes to cache on success" do
      service = ForecastService.new(location: "Brooklyn", postal_code: "11201")
      response = Response.new({ location: { name: "Brooklyn" }, current: { temp_f: 64 } }.to_json, true)
      api_client = Object.new
      cache = Object.new
      written = nil
      requested_location = nil

      cache.define_singleton_method(:read) { nil }
      cache.define_singleton_method(:write) { |data| written = data }
      api_client.define_singleton_method(:fetch_forecast) do |location|
        requested_location = location
        response
      end

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@api_client, api_client)

      result = service.call

      assert_equal "Brooklyn", requested_location
      assert_equal "Brooklyn", result.dig("location", "name")
      assert_equal 64, result.dig("current", "temp_f")
      assert_equal result, written
    end

    test "#call raises the nested API error message on failure" do
      service = ForecastService.new(location: "Chicago")
      response = Response.new({ error: { message: "Invalid request" } }.to_json, false)
      api_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      api_client.define_singleton_method(:fetch_forecast) { |_location| response }

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@api_client, api_client)

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "Invalid request", error.message
    end

    test "#call falls back to a generic message for invalid JSON failures" do
      service = ForecastService.new(location: "Seattle")
      response = Response.new("not-json", false)
      api_client = Object.new
      cache = Object.new

      cache.define_singleton_method(:read) { nil }
      api_client.define_singleton_method(:fetch_forecast) { |_location| response }

      service.instance_variable_set(:@cache, cache)
      service.instance_variable_set(:@api_client, api_client)

      error = assert_raises(ForecastService::Failure) { service.call }

      assert_equal "Weather API request failed", error.message
    end
  end
end
