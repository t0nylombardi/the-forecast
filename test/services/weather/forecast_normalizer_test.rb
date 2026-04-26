require "test_helper"

module Weather
  class ForecastNormalizerTest < ActiveSupport::TestCase
    test ".call normalizes current and daily forecast data" do
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

      result = ForecastNormalizer.call(raw)

      assert_equal "America/New_York", result[:timezone]
      assert_equal 71.5, result.dig(:current, :temperature)
      assert_equal "Clouds", result.dig(:current, :condition)
      assert_equal "broken clouds", result.dig(:current, :description)
      assert_kind_of Time, result.dig(:current, :time)
      assert_equal Date.new(2024, 4, 25), result.dig(:daily, 0, :date)
      assert_equal 78, result.dig(:daily, 0, :high)
      assert_equal "Rain", result.dig(:daily, 0, :condition)
      assert_equal "light rain", result.dig(:daily, 0, :description)
    end
  end
end
