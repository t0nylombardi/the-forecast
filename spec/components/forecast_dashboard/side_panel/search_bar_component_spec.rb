# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::SidePanel::SearchBarComponent, type: :component do
  it "renders the search form" do
    result = render_inline(described_class.new(value: "10001"))

    form = result.at_css("form")
    input = result.at_css("input[type='text']")

    expect(form["action"]).to eq(Rails.application.routes.url_helpers.update_forecast_forecasts_path)
    expect(form["data-turbo"]).to eq("false")
    expect(input["value"]).to eq("10001")
    expect(input["name"]).to eq("forecast[postal_code]")
  end
end
