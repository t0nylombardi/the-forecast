# frozen_string_literal: true

require "test_helper"

class ForecastDashboardComponentTest < ViewComponent::TestCase
  def test_component_renders_dashboard_sections
    presenter = ForecastDashboardPresenter.new(
      forecast: {
        data: {
          location: {name: "New York", country: "US", postal_code: "10001"},
          current: {
            time: Time.zone.local(2026, 4, 30, 8, 45),
            temperature: 72,
            description: "Sunny"
          },
          daily: 7.times.map do |index|
            {
              date: Date.new(2026, 4, 30) + index.days,
              description: "Sunny",
              high: 72 + index,
              low: 60 + index
            }
          end
        }
      },
      postal_code: "10001"
    )

    result = render_inline(ForecastDashboardComponent.new(data: presenter.dashboard_data))

    assert_match(/The\s*Forecast/, result.css(".forecast-brand").text)
    assert_includes result.text, "New York, US"
    assert_equal 7, result.css(".weekly-forecast__day").count
    assert_equal 0, result.css(".city-temperature-strip__item").count
  end
end
