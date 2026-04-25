# frozen_string_literal: true

module Weather
  # Handles geocoding using OpenWeather Geocoding API
  #
  # Responsibility:
  # - Convert a human-readable address into latitude and longitude
  #
  class Geocoder
    GEOCODE_URL = "http://api.openweathermap.org/geo/1.0/direct"

    API_KEY = Rails.application.credentials[:weather_api_key] || ENV["WEATHER_API_KEY"]

    class Error < StandardError; end

    # Public: Resolve location → coordinates
    #
    # @param location [String]
    # @return [Hash] { lat:, lon:, name:, country:, postal_code: nil }
    def self.call(location)
      new(location).call
    end

    def initialize(location)
      @location = location
    end

    def call
      raise Error, "Missing API key" if API_KEY.blank?
      raise Error, "Location is required" if location.blank?

      response = HTTParty.get(GEOCODE_URL, query: params, timeout: 5)

      return handle_success(response) if response.success?

      handle_failure(response)
    end

    private

    attr_reader :location

    def params
      {
        q: location,
        limit: 1,
        appid: API_KEY
      }
    end

    def handle_success(response)
      data = JSON.parse(response.body)
      raise Error, "No results found for location" if data.empty?

      first = data.first

      {
        lat: first["lat"],
        lon: first["lon"],
        name: first["name"],
        country: first["country"],
        # OpenWeather doesn't reliably return postal codes here
        postal_code: nil
      }
    end

    def handle_failure(response)
      error = parse_json_safe(response.body)
      message = error["message"] || "Geocoding request failed"
      raise Error, message
    end

    def parse_json_safe(body)
      JSON.parse(body)
    rescue
      {}
    end
  end
end
