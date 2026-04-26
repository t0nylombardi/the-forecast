require "test_helper"

module Weather
  class ForecastClientTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test "#fetch_forecast requests forecast data with the expected query" do
      response = Response.new({current: {temp: 72}}.to_json, true)
      request_url = nil
      request_query = nil

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(url, query:, timeout:) {
          request_url = url
          request_query = query
          response
        }) do
          result = ForecastClient.new.fetch_forecast(lat: 40.71, lon: -74.0)

          assert_equal ForecastClient::FORECAST_URL, request_url
          assert_equal(
            {
              lat: 40.71,
              lon: -74.0,
              exclude: "hourly,minutely,alerts",
              appid: "test-key",
              units: "imperial"
            },
            request_query
          )
          assert_equal 72, result.dig("current", "temp")
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
