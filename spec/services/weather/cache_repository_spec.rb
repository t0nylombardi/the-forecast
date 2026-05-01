# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::CacheRepository do
  describe "#read" do
    it "returns nil when nothing is cached" do
      repository = described_class.new(postal_code: "10001")
      cache = instance_double(ActiveSupport::Cache::Store)

      allow(Rails).to receive(:cache).and_return(cache)
      allow(cache).to receive(:read).with("weather_forecast:10001").and_return(nil)

      expect(repository.read).to be_nil
    end

    it "duplicates the cached payload and marks it as a cache hit" do
      repository = described_class.new(postal_code: "10001")
      stored_payload = {
        data: {current: {temperature: 72}},
        cache: {hit: false, key: "weather_forecast:10001", stored_at: Time.current}
      }
      cache = instance_double(ActiveSupport::Cache::Store)

      allow(Rails).to receive(:cache).and_return(cache)
      allow(cache).to receive(:read).with("weather_forecast:10001").and_return(stored_payload)

      result = repository.read

      expect(result.dig(:data, :current, :temperature)).to eq(72)
      expect(result.dig(:cache, :hit)).to be(true)
      expect(stored_payload.dig(:cache, :hit)).to be(false)
      expect(result).not_to equal(stored_payload)
    end
  end

  describe "#write" do
    it "stores wrapped payload with cache metadata" do
      repository = described_class.new(postal_code: "10001")
      cache = instance_double(ActiveSupport::Cache::Store)
      stored = nil

      allow(Rails).to receive(:cache).and_return(cache)
      allow(cache).to receive(:write) { |key, value, **| stored = [key, value] }

      travel_to Time.zone.parse("2026-04-24 15:45:00 UTC") do
        result = repository.write(current: {temperature: 70})

        expect(stored.first).to eq("weather_forecast:10001")
        expect(result).to eq(stored.last)
        expect(result.dig(:data, :current, :temperature)).to eq(70)
        expect(result.dig(:cache, :hit)).to be(false)
        expect(result.dig(:cache, :key)).to eq("weather_forecast:10001")
        expect(result.dig(:cache, :stored_at)).to eq(Time.zone.parse("2026-04-24 15:45:00 UTC"))
      end
    end

    it "uses the canonical 5-digit ZIP for ZIP+4 cache keys" do
      repository = described_class.new(postal_code: "10001-1234")
      cache = instance_double(ActiveSupport::Cache::Store)

      allow(Rails).to receive(:cache).and_return(cache)
      allow(cache).to receive(:read).with("weather_forecast:10001").and_return(nil)

      expect(repository.read).to be_nil
    end

    it "raises when postal code is blank" do
      repository = described_class.new(postal_code: nil)
      allow(Rails).to receive(:cache).and_return(instance_double(ActiveSupport::Cache::Store))

      expect { repository.write(current: {temperature: 70}) }
        .to raise_error(ArgumentError, "postal_code is required for caching")
    end
  end
end
