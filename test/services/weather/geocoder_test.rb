require "test_helper"

module Weather
  class GeocoderTest < ActiveSupport::TestCase
    test ".call raises when postal code is blank" do
      error = assert_raises(Geocoder::Error) { Geocoder.call("") }

      assert_equal "Postal code is required", error.message
    end

    test ".call normalizes geocoder client data" do
      client = Object.new
      requested_postal_code = nil

      client.define_singleton_method(:fetch_coordinates) do |postal_code:|
        requested_postal_code = postal_code
        {
          "zip" => "90210",
          "name" => "Beverly Hills",
          "lat" => 34.0901,
          "lon" => -118.4065,
          "country" => "US"
        }
      end

      result = Geocoder.new("90210", client: client).call

      assert_equal "90210", requested_postal_code
      assert_equal 34.0901, result[:lat]
      assert_equal(-118.4065, result[:lon])
      assert_equal "Beverly Hills", result[:city]
      assert_equal "US", result[:country]
      assert_equal "90210", result[:postal_code]
    end

    test ".call wraps geocoder client errors" do
      client = Object.new
      client.define_singleton_method(:fetch_coordinates) do |postal_code:|
        raise ApiClient::Error, "city not found"
      end

      error = assert_raises(Geocoder::Error) { Geocoder.new("00000", client: client).call }

      assert_equal "city not found", error.message
    end
  end
end
