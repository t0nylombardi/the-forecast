# frozen_string_literal: true

module WeatherApiKeyHelper
  def with_weather_api_key(value)
    stub_const("Weather::ApiClient::API_KEY", value)
    yield
  end
end

RSpec.configure do |config|
  config.include WeatherApiKeyHelper
end
