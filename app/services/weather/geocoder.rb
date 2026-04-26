# frozen_string_literal: true

module Weather
  # Handles ZIP-code geocoding using the OpenWeather Geocoding API.
  #
  # Responsibility:
  # - Convert a US ZIP code into latitude and longitude
  #
  class Geocoder
    GEOCODE_URL = "http://api.openweathermap.org/geo/1.0/zip"
    COUNTRY_CODE = "US"

    API_KEY = Rails.application.credentials[:weather_api_key] || ENV["WEATHER_API_KEY"]

    class Error < StandardError; end

    # Public: Resolve ZIP code -> coordinates
    #
    # @param postal_code [String]
    # @return [Hash] { lat:, lon:, name:, country:, postal_code: }
    def self.call(postal_code)
      new(postal_code).call
    end

    def initialize(postal_code)
      @postal_code = postal_code
    end

    def call
      raise Error, "Missing API key" if API_KEY.blank?
      raise Error, "Postal code is required" if postal_code.blank?

      response = HTTParty.get(GEOCODE_URL, query: params, timeout: 5)

      return handle_success(response) if response.success?

      handle_failure(response)
    end

    private

    attr_reader :postal_code

    def params
      {
        zip: "#{postal_code},#{COUNTRY_CODE}",
        appid: API_KEY
      }
    end

    def handle_success(response)
      data = JSON.parse(response.body)

      {
        lat: data["lat"],
        lon: data["lon"],
        name: data["name"],
        country: data["country"],
        postal_code: data["zip"]
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
