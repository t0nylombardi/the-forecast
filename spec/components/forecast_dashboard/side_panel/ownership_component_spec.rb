# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastDashboard::SidePanel::OwnershipComponent, type: :component do
  it "renders the ownership link" do
    result = render_inline(described_class.new)

    expect(result.at_css("a")["href"]).to eq("https://github.com/t0nylombardi")
    expect(result.text).to include(Date.current.year.to_s)
  end
end
