require "test_helper"

module Weather
  class GeocoderTest < ActiveSupport::TestCase
    test ".call raises when postal code is blank" do
      error = assert_raises(Geocoder::Error) { Geocoder.call("") }

      assert_equal "Postal code is required", error.message
    end

    test ".call uses the shared API client for ZIP geocoding" do
      api_client = Object.new
      requested_postal_code = nil

      api_client.define_singleton_method(:fetch_coordinates) do |postal_code:|
        requested_postal_code = postal_code
        {
          "zip" => "90210",
          "name" => "Beverly Hills",
          "lat" => 34.0901,
          "lon" => -118.4065,
          "country" => "US"
        }
      end

      geocoder = Geocoder.new("90210")
      geocoder.instance_variable_set(:@api_client, api_client)

      result = geocoder.call

      assert_equal "90210", requested_postal_code
      assert_equal 34.0901, result[:lat]
      assert_equal(-118.4065, result[:lon])
      assert_equal "Beverly Hills", result[:name]
      assert_equal "US", result[:country]
      assert_equal "90210", result[:postal_code]
    end

    test ".call wraps shared API client errors" do
      api_client = Object.new
      api_client.define_singleton_method(:fetch_coordinates) do |postal_code:|
        raise ApiClient::Error, "city not found"
      end

      geocoder = Geocoder.new("00000")
      geocoder.instance_variable_set(:@api_client, api_client)

      error = assert_raises(Geocoder::Error) { geocoder.call }

      assert_equal "city not found", error.message
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
