# frozen_string_literal: true

module ForecastDashboard
  module SidePanel
    class SearchBarComponent < ViewComponent::Base
      def initialize(value:)
        @value = value
      end

      private

      attr_reader :value
    end
  end
end
