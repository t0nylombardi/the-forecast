# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastNormalizer do
  describe ".call" do
    it "normalizes current and daily forecast data" do
      raw = {
        "timezone" => "America/New_York",
        "current" => {
          "dt" => 1_714_067_200,
          "temp" => 71.5,
          "feels_like" => 73.0,
          "humidity" => 55,
          "wind_speed" => 8.4,
          "sunrise" => 1_714_045_600,
          "sunset" => 1_714_095_900,
          "weather" => [{"main" => "Clouds", "description" => "broken clouds", "icon" => "04d"}]
        },
        "daily" => [
          {
            "dt" => 1_714_067_200,
            "summary" => "Warm",
            "temp" => {"max" => 78, "min" => 60, "day" => 74, "night" => 62},
            "humidity" => 50,
            "wind_speed" => 7.0,
            "pop" => 0.25,
            "sunrise" => 1_714_045_600,
            "sunset" => 1_714_095_900,
            "weather" => [{"main" => "Rain", "description" => "light rain", "icon" => "10d"}]
          }
        ]
      }

      result = described_class.call(raw)

      expect(result[:timezone]).to eq("America/New_York")
      expect(result.dig(:current, :temperature)).to eq(71.5)
      expect(result.dig(:current, :condition)).to eq("Clouds")
      expect(result.dig(:current, :description)).to eq("broken clouds")
      expect(result.dig(:current, :time)).to be_a(Time)
      expect(result.dig(:daily, 0, :date)).to eq(Date.new(2024, 4, 25))
      expect(result.dig(:daily, 0, :high)).to eq(78)
      expect(result.dig(:daily, 0, :condition)).to eq("Rain")
      expect(result.dig(:daily, 0, :description)).to eq("light rain")
    end
  end
end
