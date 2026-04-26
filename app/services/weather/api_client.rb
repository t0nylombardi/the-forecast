# frozen_string_literal: true

module Weather
  # Handles communication with the OpenWeather API.
  #
  # Responsibilities:
  # - Fetch forecast data using coordinates
  class ApiClient
    FORECAST_URL = "https://api.openweathermap.org/data/3.0/onecall"

    API_KEY = Rails.application.credentials[:weather_api_key] || ENV["WEATHER_API_KEY"]

    class Error < StandardError; end

    # Public: Fetch forecast data using coordinates.
    #
    # @param lat [Float]
    # @param lon [Float]
    # @return [Hash]
    def fetch_forecast(lat:, lon:)
      raise Error, "Missing API key" if API_KEY.blank?

      response = HTTParty.get(FORECAST_URL, query: forecast_params(lat, lon), timeout: 5)

      return handle_success(response) if response.success?

      handle_failure(response)
    end

    private

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

    def forecast_params(lat, lon)
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
