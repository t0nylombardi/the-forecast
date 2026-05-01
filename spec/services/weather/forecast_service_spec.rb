# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastService do
  describe ".call" do
    it "raises when the address does not include a ZIP code" do
      expect { described_class.call(address: "New York, NY") }
        .to raise_error(described_class::Failure, "Address with a 5-digit ZIP code is required")
    end
  end

  describe "#call" do
    it "returns cached data without hitting collaborators" do
      geocoder = instance_double(Weather::Geocoder)
      forecast_client = instance_double(Weather::ForecastClient)
      normalizer = class_double(Weather::ForecastNormalizer)
      cache = instance_double(Weather::CacheRepository)
      cached_payload = {data: {current: {temperature: 67}}, cache: {hit: true}}

      allow(cache).to receive(:read).and_return(cached_payload)
      allow(geocoder).to receive(:call)

      service = described_class.new(
        address: "55 Water St, Brooklyn, NY 11201",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: normalizer,
        cache: cache
      )

      expect(service.call).to eq(cached_payload)
      expect(geocoder).not_to have_received(:call)
    end

    it "geocodes, fetches, normalizes, and caches the forecast" do
      geocoder = class_double(Weather::Geocoder)
      forecast_client = instance_double(Weather::ForecastClient)
      normalizer = class_double(Weather::ForecastNormalizer)
      cache = instance_double(Weather::CacheRepository)
      raw_forecast = {"current" => {"temp" => 64}}
      normalized_forecast = {current: {temperature: 64}}
      written_payload = {
        data: normalized_forecast.merge(
          location: {name: "Brooklyn", country: "US", postal_code: "11201"}
        ),
        cache: {hit: false}
      }

      allow(cache).to receive(:read).and_return(nil)
      allow(cache).to receive(:write).and_return(written_payload)
      allow(geocoder).to receive(:call).with("11201")
        .and_return(lat: 40.695, lon: -73.989, city: "Brooklyn", country: "US", postal_code: "11201")
      allow(forecast_client).to receive(:fetch_forecast).with(lat: 40.695, lon: -73.989).and_return(raw_forecast)
      allow(normalizer).to receive(:call).with(raw_forecast).and_return(normalized_forecast)

      service = described_class.new(
        address: "55 Water St, Brooklyn, NY 11201",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: normalizer,
        cache: cache
      )

      result = service.call

      expect(cache).to have_received(:write).with(
        current: {temperature: 64},
        location: {name: "Brooklyn", country: "US", postal_code: "11201"}
      )
      expect(result).to eq(written_payload)
    end

    it "wraps geocoder errors" do
      geocoder = class_double(Weather::Geocoder)
      cache = instance_double(Weather::CacheRepository, read: nil)

      allow(geocoder).to receive(:call).and_raise(Weather::Geocoder::Error, "ZIP not found")

      service = described_class.new(
        address: "Nowhere, NY 00000",
        geocoder: geocoder,
        forecast_client: instance_double(Weather::ForecastClient),
        normalizer: class_double(Weather::ForecastNormalizer),
        cache: cache
      )

      expect { service.call }.to raise_error(described_class::Failure, "ZIP not found")
    end

    it "wraps forecast client errors" do
      geocoder = class_double(Weather::Geocoder)
      forecast_client = instance_double(Weather::ForecastClient)
      cache = instance_double(Weather::CacheRepository, read: nil)

      allow(geocoder).to receive(:call)
        .and_return(lat: 47.6062, lon: -122.3321, city: "Seattle", country: "US", postal_code: "98101")
      allow(forecast_client).to receive(:fetch_forecast)
        .and_raise(Weather::ApiClient::Error, "Weather API request failed")

      service = described_class.new(
        address: "Seattle, WA 98101",
        geocoder: geocoder,
        forecast_client: forecast_client,
        normalizer: class_double(Weather::ForecastNormalizer),
        cache: cache
      )

      expect { service.call }.to raise_error(described_class::Failure, "Weather API request failed")
    end
  end
end
