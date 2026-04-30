# frozen_string_literal: true

module ForecastDashboard
  class WeeklyForecastComponent < ViewComponent::Base
    def initialize(daily_forecast:)
      @daily_forecast = daily_forecast
    end

    private

    attr_reader :daily_forecast
  end
end
