# frozen_string_literal: true

module ForecastDashboard
  module SidePanel
    class CityInfoComponent < ViewComponent::Base
      def initialize(sidebar_info:)
        @sidebar_info = sidebar_info
      end

      private

      attr_reader :sidebar_info
    end
  end
end
