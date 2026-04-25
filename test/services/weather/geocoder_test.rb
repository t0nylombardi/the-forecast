require "test_helper"

module Weather
  class GeocoderTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test ".call raises when API key is missing" do
      with_replaced_const(Geocoder, :API_KEY, nil) do
        error = assert_raises(Geocoder::Error) { Geocoder.call("New York") }

        assert_equal "Missing API key", error.message
      end
    end

    test ".call raises when location is blank" do
      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        error = assert_raises(Geocoder::Error) { Geocoder.call("") }

        assert_equal "Location is required", error.message
      end
    end

    test ".call returns the first geocoding result" do
      response = Response.new(
        [ { lat: 40.71, lon: -74.0, name: "New York", country: "US" } ].to_json,
        true
      )
      request_url = nil
      request_query = nil
      request_timeout = nil

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(url, query:, timeout:) {
          request_url = url
          request_query = query
          request_timeout = timeout
          response
        }) do
          result = Geocoder.call("New York")

          assert_equal Geocoder::GEOCODE_URL, request_url
          assert_equal 5, request_timeout
          assert_equal({ q: "New York", limit: 1, appid: "test-key" }, request_query)
          assert_equal 40.71, result[:lat]
          assert_equal(-74.0, result[:lon])
          assert_equal "New York", result[:name]
          assert_equal "US", result[:country]
          assert_nil result[:postal_code]
        end
      end
    end

    test ".call raises when the geocoding response is empty" do
      response = Response.new([].to_json, true)

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(Geocoder::Error) { Geocoder.call("Unknown Place") }

          assert_equal "No results found for location", error.message
        end
      end
    end

    test ".call raises the API error message on failed requests" do
      response = Response.new({ message: "city not found" }.to_json, false)

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(Geocoder::Error) { Geocoder.call("Bad Place") }

          assert_equal "city not found", error.message
        end
      end
    end

    test ".call falls back to a generic error for invalid JSON failures" do
      response = Response.new("not-json", false)

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(Geocoder::Error) { Geocoder.call("Bad Place") }

          assert_equal "Geocoding request failed", error.message
        end
      end
    end

    private

    def with_replaced_const(owner, const_name, value)
      original = owner.const_get(const_name)
      owner.send(:remove_const, const_name)
      owner.const_set(const_name, value)
      yield
    ensure
      owner.send(:remove_const, const_name) if owner.const_defined?(const_name, false)
      owner.const_set(const_name, original)
    end
  end
end
