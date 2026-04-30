# frozen_string_literal: true

module ForecastDashboard
  class SidePanelComponent < ViewComponent::Base
    def initialize(search_value:, sidebar_info:)
      @search_value = search_value
      @sidebar_info = sidebar_info
    end

    private

    attr_reader :search_value, :sidebar_info
  end
end
