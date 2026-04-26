# frozen_string_literal: true

module Weather
  # Orchestrates fetching weather forecasts from cache or API.
  # Uses Weather::Geocoder to resolve a US ZIP code, Weather::ApiClient for
  # forecast requests, and CacheRepository for caching.
  #
  # @example
  #   forecast = Weather::ForecastService.call(location: "New York", postal_code: "10001")
  #
  # @raise [Weather::ForecastService::Failure] if the geocoding or forecast request fails
  class ForecastService
    class Failure < StandardError; end

    def initialize(location:, postal_code: nil)
      @location = location
      @postal_code = postal_code
      @geocoder = Geocoder
      @api_client = ApiClient.new
      @cache = CacheRepository.new(postal_code: postal_code, location: location)
    end

    # Fetches weather forecast data from the API.
    #
    # @param [String] location The location to fetch the forecast for.
    # @param [String, nil] postal_code The postal code to fetch the forecast for.
    #
    # @return [Hash] The weather forecast data.
    def self.call(location:, postal_code: nil)
      new(location: location, postal_code: postal_code).call
    end

    # Retrieves the forecast data, using cache if available.
    #
    # @return [Hash] Forecast data.
    # @raise [Failure] When geocoding or forecast lookup fails.
    def call
      return {} if postal_code.blank? && location.blank?

      cached = cache.read
      return cached if cached

      fetch_from_api
    rescue Geocoder::Error, ApiClient::Error => e
      raise Failure, e.message
    end

    private

    attr_reader :location, :postal_code, :geocoder, :api_client, :cache

    def fetch_from_api
      coordinates = geocoder.call(postal_code)
      data = api_client.fetch_forecast(lat: coordinates[:lat], lon: coordinates[:lon])
      cache.write(data)
      data
    end
  end
end
