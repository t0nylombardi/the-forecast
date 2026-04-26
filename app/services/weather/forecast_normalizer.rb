# frozen_string_literal: true

module Weather
  # Converts OpenWeather's raw forecast payload into a stable app-level contract.
  #
  # Intent:
  # - Protect the rest of the application from vendor response shape changes.
  # - Produce a predictable internal forecast contract for caching and rendering.
  # - Keep transformation logic out of both the HTTP clients and the service
  #   orchestrator.
  #
  # Views, caches, and any future consumers should depend on the normalized
  # shape produced here rather than reaching into OpenWeather's nested payload
  # directly.
  class ForecastNormalizer
    # Convenience entry point for payload normalization.
    #
    # @param data [Hash] raw forecast payload returned by OpenWeather
    # @return [Hash] normalized forecast payload
    def self.call(data)
      new(data).call
    end

    # @param data [Hash] raw parsed OpenWeather forecast payload
    def initialize(data)
      @data = data
      @timezone = data["timezone"]
    end

    # Normalizes the full forecast payload into the app-level contract.
    #
    # @return [Hash] normalized forecast with `:timezone`, `:current`, and
    #   `:daily` keys
    def call
      {
        timezone: timezone,
        current: normalize_current,
        daily: normalize_daily
      }
    end

    private

    attr_reader :data, :timezone

    # Normalizes the current conditions portion of the response.
    #
    # @return [Hash]
    def normalize_current
      current = data.fetch("current", {})

      {
        time: timestamp(current["dt"]),
        temperature: current["temp"],
        feels_like: current["feels_like"],
        humidity: current["humidity"],
        wind_speed: current["wind_speed"],
        description: current.dig("weather", 0, "description"),
        condition: current.dig("weather", 0, "main"),
        icon: current.dig("weather", 0, "icon"),
        sunrise: timestamp(current["sunrise"]),
        sunset: timestamp(current["sunset"])
      }
    end

    # Normalizes the multi-day forecast portion of the response.
    #
    # @return [Array<Hash>]
    def normalize_daily
      Array(data["daily"]).map do |day|
        {
          date: timestamp(day["dt"]).to_date,
          summary: day["summary"],
          high: day.dig("temp", "max"),
          low: day.dig("temp", "min"),
          day_temperature: day.dig("temp", "day"),
          night_temperature: day.dig("temp", "night"),
          humidity: day["humidity"],
          wind_speed: day["wind_speed"],
          precipitation_probability: day["pop"],
          description: day.dig("weather", 0, "description"),
          condition: day.dig("weather", 0, "main"),
          icon: day.dig("weather", 0, "icon"),
          sunrise: timestamp(day["sunrise"]),
          sunset: timestamp(day["sunset"])
        }
      end
    end

    # Converts a UNIX timestamp from the OpenWeather payload into a timezone-
    # aware {Time} object using the response timezone.
    #
    # @param value [Integer]
    # @return [Time]
    def timestamp(value)
      Time.use_zone(timezone) { Time.zone.at(value) }
    end
  end
end
