# frozen_string_literal: true

# Shared formatting helpers used by forecast presenters and components.
module Formatters
  class WeatherFormatter
    # @param value [Numeric, nil]
    # @return [String]
    def self.temperature(value)
      return "--" if value.blank?
      "#{value.round}°"
    end

    # @param date [#strftime, Object]
    # @return [String]
    def self.day_label(date)
      return date.strftime("%a") if date.respond_to?(:strftime)
      date.to_s
    end

    # @param time [Time, nil]
    # @param postal_code [String, nil]
    # @return [String]
    def self.timestamp(time, postal_code:)
      return "Weather data unavailable" unless time.respond_to?(:strftime)

      [
        postal_code.presence,
        time.strftime("%A, %b %-d, %Y, %-I:%M%p")
      ].compact.join(" · ")
    end
  end
end
