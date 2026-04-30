# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::SidePanel::CityInfoComponent, type: :component do
  it "renders the sidebar location info" do
    sidebar_info = ForecastDashboardPresenter::SidebarInfo.new(
      location_name: "South Salem, US",
      postal_code: "10590"
    )

    result = render_inline(described_class.new(sidebar_info:))

    expect(result.text).to include("South Salem, US")
    expect(result.text).to include("ZIP 10590")
  end
end
