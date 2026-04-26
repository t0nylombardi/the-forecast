require "test_helper"

module Weather
  class GeocoderClientTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test "#fetch_coordinates requests ZIP geocoding data" do
      response = Response.new({zip: "90210", lat: 34.0901}.to_json, true)
      request_url = nil
      request_query = nil

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(url, query:, timeout:) {
          request_url = url
          request_query = query
          response
        }) do
          result = GeocoderClient.new.fetch_coordinates(postal_code: "90210")

          assert_equal GeocoderClient::GEOCODE_URL, request_url
          assert_equal({zip: "90210,US", appid: "test-key"}, request_query)
          assert_equal "90210", result["zip"]
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
