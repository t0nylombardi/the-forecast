# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastClient do
  describe "#fetch_forecast" do
    it "requests forecast data with the expected query" do
      request_url = nil
      request_query = nil

      with_weather_api_key("test-key") do
        allow(HTTParty).to receive(:get) do |url, query:, timeout:|
          request_url = url
          request_query = query
          TestResponse.new(body: {current: {temp: 72}}.to_json, success?: true)
        end

        result = described_class.new.fetch_forecast(lat: 40.71, lon: -74.0)

        expect(request_url).to eq(described_class::FORECAST_URL)
        expect(request_query).to eq(
          lat: 40.71,
          lon: -74.0,
          exclude: "hourly,minutely,alerts",
          appid: "test-key",
          units: "imperial"
        )
        expect(result.dig("current", "temp")).to eq(72)
      end
    end
  end
end
