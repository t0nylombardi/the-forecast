# frozen_string_literal: true

module ForecastDashboard
  class TemperatureCurveComponent < ViewComponent::Base
    VIEWBOX_WIDTH = 900.0
    VIEWBOX_HEIGHT = 55.0
    PADDING = 24.0

    def initialize(daily_forecast:)
      @daily_forecast = daily_forecast
    end

    def path_definition
      return "" if temperatures.empty?

      points = temperatures.each_with_index.map do |temperature, index|
        x_position = x_step * index
        y_position = scaled_y(temperature)
        [x_position.round(2), y_position.round(2)]
      end

      first_x, first_y = points.first
      segments = points.each_cons(2).map do |(start_x, start_y), (end_x, end_y)|
        control_x = ((start_x + end_x) / 2.0).round(2)
        "C#{control_x},#{start_y} #{control_x},#{end_y} #{end_x},#{end_y}"
      end

      ["M#{first_x},#{first_y}", *segments].join(" ")
    end

    private

    attr_reader :daily_forecast

    def temperatures
      @temperatures ||= daily_forecast.map { |day| day.high.delete("°").to_f }
    end

    def x_step
      return VIEWBOX_WIDTH if temperatures.length <= 1

      VIEWBOX_WIDTH / (temperatures.length - 1)
    end

    def scaled_y(temperature)
      min = temperatures.min
      max = temperatures.max
      return VIEWBOX_HEIGHT / 2 if min == max

      ratio = (temperature - min) / (max - min)
      (VIEWBOX_HEIGHT - PADDING) - (ratio * (VIEWBOX_HEIGHT - (PADDING * 2))) + (PADDING / 2.0)
    end
  end
end
