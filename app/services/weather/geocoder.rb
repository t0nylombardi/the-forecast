# frozen_string_literal: true

module Weather
  # Resolves a US ZIP code into normalized coordinate data.
  #
  # Intent:
  # - Provide the domain-level ZIP-to-coordinate use case.
  # - Validate caller input before the HTTP client is invoked.
  # - Shield the rest of the app from OpenWeather's raw geocoding payload shape.
  #
  # This class is intentionally thin. It does not know how to perform HTTP
  # requests itself; it delegates that responsibility to {GeocoderClient}. Its
  # responsibility is to enforce input requirements and return a normalized
  # coordinate hash that the rest of the application can trust.
  class Geocoder
    # Raised when ZIP-code validation fails or when the underlying geocoding
    # client cannot successfully resolve the request.
    class Error < StandardError; end

    # Convenience entry point for ZIP-code geocoding.
    #
    # @param postal_code [String] US ZIP code to resolve
    # @return [Hash{Symbol => Object}] normalized coordinate payload
    # @raise [Error] when the ZIP code is blank or the request fails
    def self.call(postal_code)
      new(postal_code).call
    end

    # @param postal_code [String] US ZIP code supplied by the caller
    # @param client [#fetch_coordinates] endpoint client used to query
    #   OpenWeather; injected for testability and isolation
    def initialize(postal_code, client: GeocoderClient.new)
      @postal_code = postal_code
      @client = client
    end

    # Resolves the configured ZIP code into a normalized coordinate hash.
    #
    # @return [Hash] normalized payload with `:lat`, `:lon`, `:city`,
    #   `:country`, and `:postal_code`
    # @raise [Error] when the ZIP code is blank or geocoding fails
    def call
      raise Error, "Postal code is required" if postal_code.blank?

      normalize(client.fetch_coordinates(postal_code: postal_code))
    rescue ApiClient::Error => e
      raise Error, e.message
    end

    private

    attr_reader :postal_code, :client

    # Converts the raw OpenWeather geocoding payload into the application's
    # normalized coordinate contract.
    #
    # @param data [Hash] parsed geocoding payload returned by {GeocoderClient}
    # @return [Hash{Symbol => Object}]
    def normalize(data)
      {
        lat: data["lat"],
        lon: data["lon"],
        city: data["name"],
        country: data["country"],
        postal_code: data["zip"]
      }
    end
  end
end
