# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Geocoder do
  describe ".call" do
    it "raises when postal code is blank" do
      expect { described_class.call("") }
        .to raise_error(described_class::Error, "Postal code is required")
    end
  end

  describe "#call" do
    it "normalizes geocoder client data" do
      client = instance_double(Weather::GeocoderClient)

      allow(client).to receive(:fetch_coordinates).with(postal_code: "90210").and_return(
        "zip" => "90210",
        "name" => "Beverly Hills",
        "lat" => 34.0901,
        "lon" => -118.4065,
        "country" => "US"
      )

      result = described_class.new("90210", client: client).call

      expect(result).to eq(
        lat: 34.0901,
        lon: -118.4065,
        city: "Beverly Hills",
        country: "US",
        postal_code: "90210"
      )
    end

    it "wraps geocoder client errors" do
      client = instance_double(Weather::GeocoderClient)
      allow(client).to receive(:fetch_coordinates).and_raise(Weather::ApiClient::Error, "city not found")

      expect { described_class.new("00000", client: client).call }
        .to raise_error(described_class::Error, "city not found")
    end
  end
end
