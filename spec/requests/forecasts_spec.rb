# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /forecasts" do
    it "renders the dashboard using the initial IP-based postal code" do
      payload = forecast_payload(postal_code: "10001", city: "New York")

      allow(Location::IpLookupService).to receive(:call).and_return("10001")
      allow(Weather::ForecastService).to receive(:call).with(address: "10001").and_return(payload)

      get forecasts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New York, US")
      expect(response.body).to include(update_forecast_forecasts_path)
    end

    it "uses the postal code from the root query string when present" do
      payload = forecast_payload(postal_code: "10590", city: "South Salem")

      allow(Weather::ForecastService).to receive(:call).with(address: "10590").and_return(payload)
      expect(Location::IpLookupService).not_to receive(:call)

      get root_path, params: {postal_code: "10590"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("South Salem, US")
    end
  end

  describe "PATCH /forecasts/update_forecast" do
    it "redirects html requests back to the root route with the postal code" do
      payload = forecast_payload(postal_code: "10590", city: "South Salem", temperature: 61, description: "Cloudy")

      allow(Weather::ForecastService).to receive(:call).with(address: "1 Main St, South Salem, NY 10590").and_return(payload)

      patch update_forecast_forecasts_path, params: {forecast: {address: "1 Main St, South Salem, NY 10590"}}

      expect(response).to redirect_to(root_path(address: "1 Main St, South Salem, NY 10590"))
    end

    it "renders the updated forecast for turbo stream requests" do
      payload = forecast_payload(postal_code: "10001", city: "New York", temperature: 72, description: "Sunny")

      allow(Weather::ForecastService).to receive(:call).with(address: "New York, NY 10001").and_return(payload)

      patch update_forecast_forecasts_path, params: {forecast: {address: "New York, NY 10001"}}, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("turbo-stream")
      expect(response.body).to include("New York, US")
      expect(response.body).to include("72°")
    end

    it "shows an error when the lookup fails" do
      allow(Weather::ForecastService).to receive(:call).with(address: "00000")
        .and_raise(Weather::ForecastService::Failure, "ZIP not found")

      patch update_forecast_forecasts_path, params: {forecast: {address: "00000"}}, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("ZIP not found")
    end
  end

  def forecast_payload(postal_code:, city:, temperature: 68, description: "Light rain")
    {
      data: {
        location: {
          name: city,
          country: "US",
          postal_code: postal_code
        },
        current: {
          time: Time.zone.local(2026, 4, 30, 8, 45),
          temperature: temperature,
          description: description
        },
        daily: 7.times.map do |index|
          {
            date: Date.new(2026, 4, 30) + index.days,
            description: description,
            high: temperature + index,
            low: temperature - 8 + index
          }
        end
      },
      cache: {hit: false}
    }
  end
end
