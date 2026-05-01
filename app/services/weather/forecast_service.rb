# frozen_string_literal: true

module Weather
  # Orchestrates the full forecast lookup flow.
  #
  # Intent:
  # - Act as the single application entry point for "fetch me a forecast for
  #   this address".
  # - Coordinate caching, geocoding, forecast retrieval, and normalization.
  # - Translate lower-level infrastructure errors into a single service-level
  #   failure type for callers.
  #
  # Flow:
  # 1. Require an address/search string containing a ZIP code.
  # 2. Check forecast cache by ZIP code.
  # 3. Resolve ZIP code into coordinates.
  # 4. Fetch raw forecast data from OpenWeather.
  # 5. Normalize the raw API response.
  # 6. Cache and return the normalized forecast.
  #
  # Controllers and other callers should depend on this class rather than
  # coordinating lower-level collaborators themselves.
  class ForecastService
    # Raised when the overall forecast lookup use case cannot be completed.
    class Failure < StandardError; end

    # Convenience entry point for forecast lookup.
    #
    # @param address [String] address or search text containing a US ZIP code
    # @param postal_code [String] legacy explicit ZIP-code input
    # @return [Hash] wrapped normalized forecast payload
    # @raise [Failure] when validation, geocoding, forecast lookup, or caching
    #   prerequisites fail
    def self.call(address: nil, postal_code: nil)
      new(address: address, postal_code: postal_code).call
    end

    # @param address [String] address or search text containing a US ZIP code
    # @param postal_code [String] legacy explicit ZIP-code input
    # @param geocoder [#call] collaborator that resolves ZIP code to coordinates
    # @param forecast_client [#fetch_forecast] client that fetches raw forecast
    #   data for coordinates
    # @param normalizer [#call] collaborator that converts raw vendor data into
    #   the app's normalized forecast contract
    # @param cache [#read, #write] cache repository used to memoize normalized
    #   responses by ZIP code
    def initialize(
      address: nil,
      postal_code: nil,
      geocoder: Geocoder,
      forecast_client: ForecastClient.new,
      normalizer: ForecastNormalizer,
      cache: nil
    )
      @address = address
      @postal_code = postal_code
      @geocoder = geocoder
      @forecast_client = forecast_client
      @normalizer = normalizer
      @cache = cache
    end

    # Executes the forecast lookup use case.
    #
    # @return [Hash] wrapped normalized forecast payload from cache or fresh API
    #   lookup
    # @raise [Failure] when any collaborator raises a recoverable domain or API
    #   error
    def call
      raise Failure, "Address with a 5-digit ZIP code is required" if resolved_postal_code.blank?

      cached = cache_repository.read
      return cached if cached

      fetch_and_cache_forecast
    rescue Geocoder::Error, ApiClient::Error, ArgumentError => e
      raise Failure, e.message
    end

    private

    attr_reader :address, :postal_code, :geocoder, :forecast_client, :normalizer

    # Fetches, normalizes, caches, and returns a forecast for the configured ZIP
    # code.
    #
    # @return [Hash] wrapped normalized forecast payload as returned by
    #   {CacheRepository#write}
    def fetch_and_cache_forecast
      coordinates = geocoder.call(resolved_postal_code)

      raw_forecast = forecast_client.fetch_forecast(
        lat: coordinates[:lat],
        lon: coordinates[:lon]
      )

      normalized_forecast = normalizer.call(raw_forecast).merge(
        location: {
          name: coordinates[:city],
          country: coordinates[:country],
          postal_code: coordinates[:postal_code]
        }
      )

      cache_repository.write(normalized_forecast)
    end

    # @return [String, nil] canonical 5-digit ZIP code for cache/API use
    def resolved_postal_code
      @resolved_postal_code ||= postal_code.presence || AddressParser.postal_code(address)
    end

    # @return [CacheRepository]
    def cache_repository
      @cache ||= CacheRepository.new(postal_code: resolved_postal_code)
    end
  end
end
