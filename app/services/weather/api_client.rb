# frozen_string_literal: true

module Weather
  # Shared OpenWeather API behavior.
  #
  # Intent:
  # - Provide one place for transport-level OpenWeather behavior.
  # - Keep endpoint-specific clients focused on endpoint-specific query logic.
  # - Enforce a consistent error-handling contract across all API calls.
  #
  # This class is not meant to be called directly by controllers or higher-level
  # domain services. Instead, concrete clients such as {GeocoderClient} and
  # {ForecastClient} inherit from it and supply only the endpoint URL, query
  # parameters, and default failure message for their specific use case.
  #
  # The goal is to keep the HTTP boundary SOLID:
  # - subclasses own endpoint-specific request construction
  # - this base class owns shared request execution and response handling
  #
  # @abstract Subclass and call {#get_json} to perform API requests.
  class ApiClient
    # OpenWeather API key loaded from Rails credentials or environment.
    #
    # @return [String, nil]
    API_KEY = Rails.application.credentials[:weather_api_key] || ENV["WEATHER_API_KEY"]

    # Shared timeout for all outbound OpenWeather requests.
    #
    # @return [Integer]
    TIMEOUT_SECONDS = 5

    # Raised when a request cannot be completed successfully or when shared
    # client prerequisites are not met.
    #
    # @see #api_key
    # @see #get_json
    class Error < StandardError; end

    private

    # Returns the configured OpenWeather API key.
    #
    # @return [String]
    # @raise [Error] when no API key has been configured
    def api_key
      raise Error, "Missing OpenWeather API key" if API_KEY.blank?

      API_KEY
    end

    # Executes a GET request and parses a successful JSON response.
    #
    # Concrete API clients delegate to this helper so response parsing, timeout
    # behavior, and error handling remain consistent regardless of endpoint.
    #
    # @param url [String] the full OpenWeather endpoint URL
    # @param query [Hash] query string parameters for the request
    # @param default_error [String] fallback error message when the API does not
    #   return a usable message payload
    # @return [Hash, Array] parsed JSON body from the response
    # @raise [Error] when the request fails or returns non-success status
    def get_json(url, query:, default_error:)
      response = HTTParty.get(url, query: query, timeout: TIMEOUT_SECONDS)

      return JSON.parse(response.body) if response.success?

      handle_failure(response, default_error:)
    end

    # Raises a normalized API error from a failed HTTP response.
    #
    # @param response [#body] HTTP response object returned by HTTParty
    # @param default_error [String] fallback message when the response body is
    #   empty, invalid, or missing a `message` field
    # @raise [Error] always
    def handle_failure(response, default_error:)
      payload = parse_json_safe(response.body)
      message = payload["message"].presence || default_error

      raise Error, message
    end

    # Parses JSON while swallowing parser errors into an empty hash.
    #
    # This is intentionally defensive because upstream APIs can return non-JSON
    # or partially structured failure responses.
    #
    # @param body [String]
    # @return [Hash, Array]
    def parse_json_safe(body)
      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end
  end
end
