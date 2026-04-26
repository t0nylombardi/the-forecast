require "test_helper"

module Weather
  class GeocoderTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test ".call raises when API key is missing" do
      with_replaced_const(Geocoder, :API_KEY, nil) do
        error = assert_raises(Geocoder::Error) { Geocoder.call("10001") }

        assert_equal "Missing API key", error.message
      end
    end

    test ".call raises when postal code is blank" do
      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        error = assert_raises(Geocoder::Error) { Geocoder.call("") }

        assert_equal "Postal code is required", error.message
      end
    end

    test ".call returns the ZIP geocoding result" do
      response = Response.new(
        { zip: "90210", name: "Beverly Hills", lat: 34.0901, lon: -118.4065, country: "US" }.to_json,
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
          result = Geocoder.call("90210")

          assert_equal Geocoder::GEOCODE_URL, request_url
          assert_equal 5, request_timeout
          assert_equal({ zip: "90210,US", appid: "test-key" }, request_query)
          assert_equal 34.0901, result[:lat]
          assert_equal(-118.4065, result[:lon])
          assert_equal "Beverly Hills", result[:name]
          assert_equal "US", result[:country]
          assert_equal "90210", result[:postal_code]
        end
      end
    end

    test ".call raises the API error message on failed requests" do
      response = Response.new({ message: "city not found" }.to_json, false)

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(Geocoder::Error) { Geocoder.call("00000") }

          assert_equal "city not found", error.message
        end
      end
    end

    test ".call falls back to a generic error for invalid JSON failures" do
      response = Response.new("not-json", false)

      with_replaced_const(Geocoder, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(Geocoder::Error) { Geocoder.call("00000") }

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
