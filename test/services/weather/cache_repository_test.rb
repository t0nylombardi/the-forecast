require "test_helper"

module Weather
  class CacheRepositoryTest < ActiveSupport::TestCase
    test "#read returns nil when nothing is cached" do
      repository = CacheRepository.new(postal_code: "10001")
      cache = build_cache_double({})

      stub_singleton_method(Rails, :cache, -> { cache }) do
        assert_nil repository.read
      end
    end

    test "#read returns a duplicated cached payload and marks it as a cache hit" do
      repository = CacheRepository.new(postal_code: "10001")
      stored_payload = {
        data: {current: {temperature: 72}},
        cache: {hit: false, key: "weather_forecast:10001", stored_at: Time.current}
      }
      cache = build_cache_double("weather_forecast:10001" => stored_payload)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        result = repository.read

        assert_equal 72, result.dig(:data, :current, :temperature)
        assert_equal true, result.dig(:cache, :hit)
        assert_equal false, stored_payload.dig(:cache, :hit)
        refute_same stored_payload, result
      end
    end

    test "#write stores wrapped payload with cache metadata" do
      repository = CacheRepository.new(postal_code: "10001")
      store = {}
      cache = build_cache_double(store)

      stub_singleton_method(Rails, :cache, -> { cache }) do
        travel_to Time.zone.parse("2026-04-24 15:45:00 UTC") do
          result = repository.write(current: {temperature: 70})

          assert_equal result, store["weather_forecast:10001"]
          assert_equal 70, result.dig(:data, :current, :temperature)
          assert_equal false, result.dig(:cache, :hit)
          assert_equal "weather_forecast:10001", result.dig(:cache, :key)
          assert_equal Time.zone.parse("2026-04-24 15:45:00 UTC"), result.dig(:cache, :stored_at)
        end
      end
    end

    test "#write raises when postal code is blank" do
      repository = CacheRepository.new(postal_code: nil)
      cache = build_cache_double({})

      stub_singleton_method(Rails, :cache, -> { cache }) do
        error = assert_raises(ArgumentError) { repository.write(current: {temperature: 70}) }

        assert_equal "postal_code is required for caching", error.message
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
