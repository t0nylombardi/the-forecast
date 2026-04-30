# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::TemperatureCurveComponent, type: :component do
  it "builds an svg path from temperatures" do
    days = [
      ForecastDashboardPresenter::DailyForecast.new(label: "Thu", summary: "Sunny", high: "70°", low: "60°"),
      ForecastDashboardPresenter::DailyForecast.new(label: "Fri", summary: "Cloudy", high: "75°", low: "62°"),
      ForecastDashboardPresenter::DailyForecast.new(label: "Sat", summary: "Rain", high: "68°", low: "59°")
    ]

    component = described_class.new(daily_forecast: days)

    expect(component.path_definition).to start_with("M")
    expect(component.path_definition).to include("C")
  end

  it "returns an empty path for empty data" do
    expect(described_class.new(daily_forecast: []).path_definition).to eq("")
  end
end
