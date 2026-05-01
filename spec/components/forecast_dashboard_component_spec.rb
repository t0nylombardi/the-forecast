# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboardComponent, type: :component do
  it "renders the dashboard sections" do
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

    result = render_inline(described_class.new(data: presenter.dashboard_data))

    expect(result.css(".forecast-brand").text).to match(/The\s*Forecast/)
    expect(result.text).to include("New York, US")
    expect(result.css(".weekly-forecast__day").length).to eq(7)
    expect(result.at_css(".forecast-app")["style"]).to include("/weather/sunny.jpg")
    expect(result.at_css(".forecast-app")["style"]).to include("cover no-repeat")
  end

  it "renders an alert when one is present" do
    data = ForecastDashboardPresenter.new(forecast: nil, postal_code: "10001").dashboard_data

    result = render_inline(described_class.new(data:, alert: "ZIP not found"))

    expect(result.css(".forecast-alert").text).to include("ZIP not found")
  end
end
