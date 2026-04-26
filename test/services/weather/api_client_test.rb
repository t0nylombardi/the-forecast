require "test_helper"

module Weather
  class ApiClientTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test "#fetch_forecast raises when API key is missing" do
      with_replaced_const(ApiClient, :API_KEY, nil) do
        error = assert_raises(ApiClient::Error) do
          ApiClient.new.fetch_forecast(lat: 40.71, lon: -74.0)
        end

        assert_equal "Missing API key", error.message
      end
    end

    test "#fetch_forecast returns parsed weather data" do
      response = Response.new({ current: { temp: 72 }, daily: [] }.to_json, true)
      request_url = nil
      request_query = nil
      request_timeout = nil

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(url, query:, timeout:) {
          request_url = url
          request_query = query
          request_timeout = timeout
          response
        }) do
          result = ApiClient.new.fetch_forecast(lat: 40.71, lon: -74.0)

          assert_equal ApiClient::FORECAST_URL, request_url
          assert_equal 5, request_timeout
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

    test "#fetch_forecast raises the API error message on failed requests" do
      response = Response.new({ message: "invalid coordinates" }.to_json, false)

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(ApiClient::Error) do
            ApiClient.new.fetch_forecast(lat: 0, lon: 0)
          end

          assert_equal "invalid coordinates", error.message
        end
      end
    end

    test "#fetch_forecast falls back to a generic error for invalid JSON failures" do
      response = Response.new("not-json", false)

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(ApiClient::Error) do
            ApiClient.new.fetch_forecast(lat: 0, lon: 0)
          end

          assert_equal "Weather API request failed", error.message
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
