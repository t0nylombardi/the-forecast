# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::SidePanelComponent, type: :component do
  it "renders the search form and sidebar metadata" do
    sidebar_info = ForecastDashboardPresenter::SidebarInfo.new(
      location_name: "New York, US",
      postal_code: "10001"
    )

    result = render_inline(described_class.new(search_value: "10001", sidebar_info:))

    expect(result.text).to include("New York, US")
    expect(result.text).to include("ZIP 10001")
    expect(result.at_css("input[type='text']")["value"]).to eq("10001")
  end
end
