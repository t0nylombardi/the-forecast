# frozen_string_literal: true

module Weather
  # Handles storing and retrieving weather forecasts from cache.
  class CacheRepository
    # @param postal_code [String, nil]
    def initialize(postal_code: nil, location: nil)
      @postal_code = postal_code
      @location = location
    end

    # Reads cached forecast if present.
    #
    # @return [Hash, nil] Cached data or nil.
    def read
      normalize(Rails.cache.read(cache_key))
    end

    # Writes forecast data into cache.
    #
    # @param data [Hash]
    # @return [void]
    def write(data)
      Rails.cache.write(cache_key, data.merge(cached_metadata), expires_in: 30.minutes)
    end

    private

    attr_reader :postal_code, :location

    def cache_key
      key = postal_code.presence || location&.parameterize
      "weather_forecast_#{key}"
    end

    def normalize(data)
      return unless data
      data.is_a?(String) ? JSON.parse(data) : data
    end

    def cached_metadata
      {
        cached: {
          at: Time.current.in_time_zone("Eastern Time (US & Canada)")
            .strftime("%b %d, %Y %I:%M %p"),
          location: location,
          postal_code: postal_code
        }
      }
    end
  end
end
