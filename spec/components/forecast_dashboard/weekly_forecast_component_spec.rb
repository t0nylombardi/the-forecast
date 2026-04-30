# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::WeeklyForecastComponent, type: :component do
  it "renders each forecast day" do
    days = [
      ForecastDashboardPresenter::DailyForecast.new(label: "Thu", summary: "Sunny", high: "75°", low: "60°"),
      ForecastDashboardPresenter::DailyForecast.new(label: "Fri", summary: "Rain", high: "70°", low: "58°")
    ]

    result = render_inline(described_class.new(daily_forecast: days))

    expect(result.css(".weekly-forecast__day").length).to eq(2)
    expect(result.text).to include("Sunny")
    expect(result.text).to include("high 75°")
  end
end
