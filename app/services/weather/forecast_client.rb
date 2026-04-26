# frozen_string_literal: true

module Weather
  # Client for OpenWeather One Call forecast data.
  #
  # Intent:
  # - Encapsulate the OpenWeather One Call forecast endpoint.
  # - Keep forecast-specific query construction out of orchestration code.
  # - Return raw vendor data so normalization remains a separate responsibility.
  #
  # This class intentionally does not reshape the response payload. That work is
  # delegated to {ForecastNormalizer} so transport concerns and domain
  # transformation concerns remain separate.
  class ForecastClient < ApiClient
    # OpenWeather One Call 3.0 endpoint.
    #
    # @return [String]
    FORECAST_URL = "https://api.openweathermap.org/data/3.0/onecall"

    # Fetches raw forecast data for the given coordinates.
    #
    # @param lat [Float] latitude used for the forecast lookup
    # @param lon [Float] longitude used for the forecast lookup
    # @return [Hash] raw parsed OpenWeather forecast payload
    # @raise [ApiClient::Error] when the request fails or the API key is missing
    def fetch_forecast(lat:, lon:)
      get_json(
        FORECAST_URL,
        query: {
          lat: lat,
          lon: lon,
          exclude: "hourly,minutely,alerts",
          appid: api_key,
          units: "imperial"
        },
        default_error: "Weather API request failed"
      )
    end
  end
end
