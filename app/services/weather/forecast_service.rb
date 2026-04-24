module Weather
  class ForecastService
    include HTTParty

    base_uri "https://api.weatherapi.com/v1"

    def initialize(location:, zip_code:)
      @location = location
      @zip_code = zip_code
    end

    def self.call(location:, zip_code:)
      new(location:, zip_code:).call
    end

    def call
      response = self.class.get(
        "/forecast.json",
        query: {
          key: ENV.fetch("WEATHER_API_KEY", nil),
          q: query,
          days: 5,
          aqi: "no",
          alerts: "no"
        }
      )

      return response.parsed_response if response.success?

      {"error" => {"message" => error_message_for(response)}}
    rescue StandardError
      {"error" => {"message" => "Unable to fetch forecast right now."}}
    end

    private

    attr_reader :location, :zip_code

    def query
      zip_code.presence || location.to_s.strip
    end

    def error_message_for(response)
      response.parsed_response.dig("error", "message").presence || "Unable to fetch forecast right now."
    end
  end
end
