# frozen_string_literal: true

module Weather
  # Stores and retrieves normalized forecasts by ZIP code.
  #
  # Intent:
  # - Encapsulate cache key generation and cache metadata shape.
  # - Keep cache semantics out of controllers and orchestration services.
  # - Return a consistent envelope regardless of cache hit or fresh write.
  #
  # The cache return shape is intentionally consistent:
  #
  # {
  #   data: { ...normalized forecast... },
  #   cache: { hit:, key:, stored_at: }
  # }
  class CacheRepository
    # Cache time-to-live for normalized forecast payloads.
    #
    # @return [ActiveSupport::Duration]
    TTL = 30.minutes

    # @param postal_code [String] ZIP code used to derive the cache key
    def initialize(postal_code:)
      @postal_code = postal_code
    end

    # Reads a cached forecast envelope.
    #
    # On a cache hit, a deep-duplicated payload is returned with the `:hit`
    # metadata updated to `true`. Returning a duplicate prevents accidental
    # mutation of the cached object in memory.
    #
    # @return [Hash, nil] wrapped cached payload or nil on cache miss
    def read
      cached = Rails.cache.read(cache_key)
      return unless cached

      cached.deep_dup.tap do |payload|
        payload[:cache][:hit] = true
      end
    end

    # Wraps and persists a normalized forecast payload in cache.
    #
    # @param data [Hash] normalized forecast payload
    # @return [Hash] wrapped cache payload written to the store
    def write(data)
      payload = wrap(data)
      Rails.cache.write(cache_key, payload, expires_in: TTL)
      payload
    end

    private

    attr_reader :postal_code

    # Builds the cache key for the configured ZIP code.
    #
    # @return [String]
    # @raise [ArgumentError] when no postal code is available
    def cache_key
      raise ArgumentError, "postal_code is required for caching" if postal_code.blank?

      "weather_forecast:#{postal_code}"
    end

    # Builds the cache envelope returned to callers and stored in the cache.
    #
    # @param data [Hash] normalized forecast payload
    # @return [Hash]
    def wrap(data)
      {
        data: data,
        cache: {
          hit: false,
          key: cache_key,
          stored_at: Time.current
        }
      }
    end
  end
end
