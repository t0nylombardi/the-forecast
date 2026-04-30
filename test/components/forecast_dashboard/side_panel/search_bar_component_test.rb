# frozen_string_literal: true

require "test_helper"

class ForecastDashboard::SidePanel::SearchBarComponentTest < ViewComponent::TestCase
  def test_component_renders_search_form
    result = render_inline(ForecastDashboard::SidePanel::SearchBarComponent.new(value: "10001"))

    form = result.at_css("form")
    input = result.at_css("input[type='text']")

    assert_equal Rails.application.routes.url_helpers.update_forecast_forecasts_path, form["action"]
    assert_equal "10001", input["value"]
    assert_equal "forecast[postal_code]", input["name"]
  end
end
