# frozen_string_literal: true

module Weather
  # Orchestrates fetching weather forecasts from cache or API.
  # Uses Weather::ApiClient for API requests and CacheRepository for caching.
  #
  # @example
  #   forecast = Weather::ForecastService.call(location: "New York", postal_code: "10001")
  #
  # @raise [Weather::ForecastService::Failure] if the API request fails
  class ForecastService
    API_KEY = Rails.application.credentials[:weather_api_key]
    class Failure < StandardError; end

    def initialize(location:, postal_code: nil)
      @location = location
      @postal_code = postal_code
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
    # @raise [Failure] When API request fails.
    def call
      return {} unless location

      cached = cache.read
      return cached if cached

      fetch_from_api
    end

    private

    attr_reader :location, :postal_code, :api_client, :cache

    # Fetches weather forecast data from the API.
    #
    # @return [Hash] The weather forecast data.
    def fetch_from_api
      response = perform_request
      return handle_success(response) if response.success?
      handle_failure(response)
    end

    def perform_request
      api_client.fetch_forecast(location)
    end

    def handle_success(response)
      data = parse_json(response.body)
      cache.write(data)
      data
    end

    def handle_failure(response)
      error_data = parse_json_safe(response.body)
      message = extract_error_message(error_data)
      raise Failure, message
    end

    def parse_json(body)
      JSON.parse(body)
    end

    def parse_json_safe(body)
      parse_json(body)
    rescue
      {}
    end

    def extract_error_message(error_data)
      error_data["error"]&.dig("message") || "Weather API request failed"
    end
  end
end
