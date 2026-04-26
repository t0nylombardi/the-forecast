# frozen_string_literal: true

module Weather
  # Client for OpenWeather ZIP geocoding.
  #
  # Intent:
  # - Encapsulate the OpenWeather ZIP geocoding endpoint.
  # - Keep ZIP-code request construction separate from higher-level domain
  #   validation and normalization logic.
  #
  # This client returns the raw parsed OpenWeather payload. The companion
  # {Geocoder} class is responsible for transforming that vendor-specific shape
  # into the application's normalized coordinate contract.
  class GeocoderClient < ApiClient
    # OpenWeather ZIP geocoding endpoint.
    #
    # @return [String]
    GEOCODE_URL = "https://api.openweathermap.org/geo/1.0/zip"

    # Country code appended to all postal-code lookups. The current application
    # scope is limited to US ZIP codes.
    #
    # @return [String]
    COUNTRY_CODE = "US"

    # Fetches raw geocoding data for a US ZIP code.
    #
    # @param postal_code [String] US ZIP code supplied by the caller
    # @return [Hash] raw parsed OpenWeather geocoding payload
    # @raise [ApiClient::Error] when the request fails or the API key is missing
    def fetch_coordinates(postal_code:)
      get_json(
        GEOCODE_URL,
        query: {
          zip: "#{postal_code},#{COUNTRY_CODE}",
          appid: api_key
        },
        default_error: "Geocoding request failed"
      )
    end
  end
end
