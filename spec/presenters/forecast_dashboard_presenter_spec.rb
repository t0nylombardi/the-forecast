# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboardPresenter do
  describe "#dashboard_data" do
    it "builds display data from a normalized forecast payload" do
      forecast = {
        data: {
          location: {
            name: "New York",
            country: "US",
            postal_code: "10001"
          },
          current: {
            time: Time.zone.local(2026, 4, 30, 8, 45),
            temperature: 72.2,
            description: "sunny"
          },
          daily: [
            {
              date: Date.new(2026, 4, 30),
              description: "sunny",
              high: 75.9,
              low: 60.2
            }
          ]
        }
      }

      data = described_class.new(forecast: forecast, postal_code: "10001").dashboard_data

      expect(data.search_value).to eq("10001")
      expect(data.sidebar_info.location_name).to eq("New York, US")
      expect(data.sidebar_info.postal_code).to eq("10001")
      expect(data.hero.title).to eq("New York, US")
      expect(data.hero.temperature).to eq("72°")
      expect(data.hero.description).to include("Sunny")
      expect(data.hero.description).to include("High 76° / Low 60°")
      expect(data.daily_forecast.first.label).to eq("Thu")
      expect(data.daily_forecast.first.summary).to eq("Sunny")
      expect(data.background_image_path).to eq("/weather/sunny.jpg")
    end

    it "falls back cleanly when no forecast is present" do
      data = described_class.new(forecast: nil, postal_code: nil).dashboard_data

      expect(data.search_value).to eq("")
      expect(data.hero.timestamp).to eq("Weather data unavailable")
      expect(data.daily_forecast.length).to eq(7)
      expect(data.daily_forecast.first.high).to eq("--")
      expect(data.background_image_path).to eq("/weather/sunny.jpg")
    end

    it "uses the rainy background for rainy descriptions" do
      forecast = {
        current: {temperature: 54, description: "light rain"},
        daily: []
      }

      data = described_class.new(forecast:, postal_code: "10001").dashboard_data

      expect(data.background_image_path).to eq("/weather/cloudy-rain.jpg")
    end

    it "falls back to weather condition text when description is missing" do
      forecast = {
        current: {temperature: 54, condition: "Rain"},
        daily: []
      }

      data = described_class.new(forecast:, postal_code: "10001").dashboard_data

      expect(data.background_image_path).to eq("/weather/cloudy-rain.jpg")
    end
  end
end
