# frozen_string_literal: true

module Weather
  # Handles communication with the OpenWeather API.
  #
  # Responsibilities:
  # - Fetch current weather using coordinates
  #
  # NOTE:
  # OpenWeather separates geocoding and weather endpoints.
  #
  class ApiClient
    CURRENT_WEATHER_URL = "https://api.openweathermap.org/data/3.0/onecall?"

    API_KEY = Rails.application.credentials[:weather_api_key] || ENV["WEATHER_API_KEY"]

    class Error < StandardError; end

    # Public: Fetch weather using coordinates
    #
    # @param lat [Float]
    # @param lon [Float]
    # @return [Hash]
    def fetch_current_weather(lat:, lon:)
      raise Error, "Missing API key" if API_KEY.blank?

      fetch_weather_by_coords(lat, lon)
    end

    private

    # Step 2: Fetch weather by lat/lon
    #
    # @param lat [Float]
    # @param lon [Float]
    # @return [Hash]
    def fetch_weather_by_coords(lat, lon)
      response = HTTParty.get(CURRENT_WEATHER_URL, query: weather_params(lat, lon))

      return handle_success(response) if response.success?

      handle_failure(response)
    end

    def handle_success(response)
      JSON.parse(response.body)
    end

    def handle_failure(response)
      error = parse_json_safe(response.body)
      message = error["message"] || "Weather API request failed"
      raise Error, message
    end

    def parse_json_safe(body)
      JSON.parse(body)
    rescue
      {}
    end

    def weather_params(lat, lon)
      {
        lat: lat,
        lon: lon,
        exclude: "hourly,minutely,alerts",
        appid: API_KEY,
        units: "imperial"
      }
    end
  end
end
