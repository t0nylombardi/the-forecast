# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::HeroComponent, type: :component do
  it "renders hero content" do
    hero = ForecastDashboardPresenter::Hero.new(
      title: "South Salem, US",
      timestamp: "10590 · Thursday, Apr 30, 2026, 8:45AM",
      temperature: "61°",
      description: "Cloudy. High 61° / Low 53°"
    )

    result = render_inline(described_class.new(hero:))

    expect(result.css(".forecast-hero__title").text).to include("South Salem, US")
    expect(result.text).to include("61°")
    expect(result.text).to include("Cloudy")
  end
end
