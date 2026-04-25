require "test_helper"

module Weather
  class CacheRepositoryTest < ActiveSupport::TestCase
    test "#read returns parsed JSON when the cache stores a string" do
      repository = CacheRepository.new(postal_code: "10001", location: "New York")
      store = { "weather_forecast_10001" => { temp: 72 }.to_json }
      cache = build_cache_double(store)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        assert_equal 72, repository.read["temp"]
      end
    end

    test "#read returns hashes unchanged" do
      repository = CacheRepository.new(location: "New York")
      store = { "weather_forecast_new-york" => { "temp" => 68 } }
      cache = build_cache_double(store)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        assert_equal({ "temp" => 68 }, repository.read)
      end
    end

    test "#read returns nil when nothing is cached" do
      repository = CacheRepository.new(location: "Boston")
      cache = build_cache_double({})

      stub_singleton_method(Rails, :cache, -> { cache }) do
        assert_nil repository.read
      end
    end

    test "#write stores data with cache metadata using postal code when present" do
      repository = CacheRepository.new(postal_code: "10001", location: "New York")
      store = {}
      cache = build_cache_double(store)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        travel_to Time.zone.parse("2026-04-24 15:45:00 UTC") do
          repository.write({ "temp" => 70 })
        end

        cached = store["weather_forecast_10001"]

        assert_equal 70, cached["temp"]
        assert_equal "New York", cached.dig(:cached, :location)
        assert_equal "10001", cached.dig(:cached, :postal_code)
        assert_equal "Apr 24, 2026 11:45 AM", cached.dig(:cached, :at)
      end
    end

    test "#write parameterizes the location when postal code is absent" do
      repository = CacheRepository.new(location: "San Francisco, CA")
      store = {}
      cache = build_cache_double(store)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        travel_to Time.zone.parse("2026-04-24 12:00:00 UTC") do
          repository.write({ "temp" => 58 })
        end

        cached = store["weather_forecast_san-francisco-ca"]

        assert_equal 58, cached["temp"]
      end
    end

    private

    def build_cache_double(store)
      Object.new.tap do |cache|
        cache.define_singleton_method(:read) { |key| store[key] }
        cache.define_singleton_method(:write) { |key, value, **_options| store[key] = value }
      end
    end
  end
end
