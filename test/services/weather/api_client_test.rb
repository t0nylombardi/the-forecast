require "test_helper"

module Weather
  class ApiClientTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    class TestClient < ApiClient
      def fetch_payload
        get_json(
          "https://example.com/weather",
          query: {appid: api_key},
          default_error: "Request failed"
        )
      end
    end

    test "#get_json returns parsed JSON for successful responses" do
      response = Response.new({"status" => "ok"}.to_json, true)
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
          result = TestClient.new.fetch_payload

          assert_equal "https://example.com/weather", request_url
          assert_equal({appid: "test-key"}, request_query)
          assert_equal ApiClient::TIMEOUT_SECONDS, request_timeout
          assert_equal "ok", result["status"]
        end
      end
    end

    test "#api_key raises when the API key is missing" do
      with_replaced_const(ApiClient, :API_KEY, nil) do
        error = assert_raises(ApiClient::Error) { TestClient.new.fetch_payload }

        assert_equal "Missing OpenWeather API key", error.message
      end
    end

    test "#handle_failure raises the API error message on failed requests" do
      response = Response.new({message: "city not found"}.to_json, false)

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(ApiClient::Error) { TestClient.new.fetch_payload }

          assert_equal "city not found", error.message
        end
      end
    end

    test "#handle_failure falls back to the default error for invalid JSON" do
      response = Response.new("not-json", false)

      with_replaced_const(ApiClient, :API_KEY, "test-key") do
        stub_singleton_method(HTTParty, :get, ->(*, **) { response }) do
          error = assert_raises(ApiClient::Error) { TestClient.new.fetch_payload }

          assert_equal "Request failed", error.message
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
