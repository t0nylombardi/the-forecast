# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::GeocoderClient do
  describe "#fetch_coordinates" do
    it "requests zip geocoding data" do
      request_url = nil
      request_query = nil

      with_weather_api_key("test-key") do
        allow(HTTParty).to receive(:get) do |url, query:, timeout:|
          request_url = url
          request_query = query
          TestResponse.new(body: {zip: "90210", lat: 34.0901}.to_json, success?: true)
        end

        result = described_class.new.fetch_coordinates(postal_code: "90210")

        expect(request_url).to eq(described_class::GEOCODE_URL)
        expect(request_query).to eq(zip: "90210,US", appid: "test-key")
        expect(result["zip"]).to eq("90210")
      end
    end
  end
end
