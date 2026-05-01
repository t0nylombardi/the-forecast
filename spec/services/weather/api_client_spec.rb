# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ApiClient do
  let(:test_client_class) do
    Class.new(described_class) do
      def fetch_payload
        send(
          :get_json,
          "https://example.com/weather",
          query: {appid: send(:api_key)},
          default_error: "Request failed"
        )
      end
    end
  end

  let(:test_client) { test_client_class.new }

  describe "#get_json" do
    it "returns parsed JSON for successful responses" do
      request_url = nil
      request_query = nil
      request_timeout = nil

      with_weather_api_key("test-key") do
        allow(HTTParty).to receive(:get) do |url, query:, timeout:|
          request_url = url
          request_query = query
          request_timeout = timeout
          TestResponse.new(body: {status: "ok"}.to_json, success?: true)
        end

        result = test_client.fetch_payload

        expect(request_url).to eq("https://example.com/weather")
        expect(request_query).to eq(appid: "test-key")
        expect(request_timeout).to eq(described_class::TIMEOUT_SECONDS)
        expect(result["status"]).to eq("ok")
      end
    end

    it "raises when the API key is missing" do
      with_weather_api_key(nil) do
        expect { test_client.fetch_payload }
          .to raise_error(described_class::Error, "Missing OpenWeather API key")
      end
    end

    it "raises the API error message on failed requests" do
      with_weather_api_key("test-key") do
        allow(HTTParty).to receive(:get)
          .and_return(TestResponse.new(body: {message: "city not found"}.to_json, success?: false))

        expect { test_client.fetch_payload }
          .to raise_error(described_class::Error, "city not found")
      end
    end

    it "falls back to the default error for invalid JSON" do
      with_weather_api_key("test-key") do
        allow(HTTParty).to receive(:get)
          .and_return(TestResponse.new(body: "not-json", success?: false))

        expect { test_client.fetch_payload }
          .to raise_error(described_class::Error, "Request failed")
      end
    end
  end
end
