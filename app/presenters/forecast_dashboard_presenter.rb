# frozen_string_literal: true

# Converts normalized forecast data into the view-ready dashboard contract.
#
# This presenter owns the display-oriented transformations for the forecast
# dashboard, including hero text, weekly forecast rows, fallback copy, and
# weather-driven background image selection.
class ForecastDashboardPresenter
  # Lightweight row object for the weekly forecast strip.
  DailyForecast = Data.define(:label, :summary, :high, :low)
  # Sidebar metadata shown beside the dashboard.
  SidebarInfo = Data.define(:location_name, :postal_code)
  # Primary hero content displayed at the top of the dashboard.
  Hero = Data.define(:title, :timestamp, :temperature, :description)
  # Full dashboard view model consumed by `ForecastDashboardComponent`.
  DashboardData = Data.define(:search_value, :sidebar_info, :hero, :daily_forecast, :background_image_path)

  DEFAULT_DESCRIPTION = "Enter a valid US ZIP code to load the current weather and 7-day forecast."

  # @param forecast [Hash, nil] normalized forecast payload, optionally wrapped
  #   in a `{ data: ... }` envelope
  # @param postal_code [String, nil]
  def initialize(forecast:, postal_code:)
    @forecast = forecast&.dig(:data) || forecast || {}
    @postal_code = postal_code
  end

  # @return [DashboardData]
  def dashboard_data
    DashboardData.new(
      search_value: postal_code.to_s,
      sidebar_info: sidebar_info,
      hero: hero,
      daily_forecast: daily_forecast,
      background_image_path: background_image_path
    )
  end

  private

  attr_reader :forecast, :postal_code

  # @return [SidebarInfo]
  def sidebar_info
    SidebarInfo.new(
      location_name: location_name,
      postal_code: postal_code
    )
  end

  # @return [Hero]
  def hero
    Hero.new(
      title: location_name,
      timestamp: Formatters::WeatherFormatter.timestamp(current_time, postal_code:),
      temperature: Formatters::WeatherFormatter.temperature(current_temp),
      description: description
    )
  end

  # @return [Array<DailyForecast>]
  def daily_forecast
    return fallback_forecast if days.empty?

    days.first(7).map do |day|
      DailyForecast.new(
        label: Formatters::WeatherFormatter.day_label(day[:date]),
        summary: day[:description].to_s.capitalize,
        high: Formatters::WeatherFormatter.temperature(day[:high]),
        low: Formatters::WeatherFormatter.temperature(day[:low])
      )
    end
  end

  # @return [String]
  def location_name
    [forecast.dig(:location, :name), forecast.dig(:location, :country)]
      .compact_blank
      .join(", ")
      .presence || "Unknown location"
  end

  # @return [Time, nil]
  def current_time
    forecast.dig(:current, :time)
  end

  # @return [Numeric, nil]
  def current_temp
    forecast.dig(:current, :temperature)
  end

  # @return [String]
  def description
    [
      weather_text&.capitalize,
      today_range
    ].compact.join(". ").presence || DEFAULT_DESCRIPTION
  end

  # Selects the dashboard background image for the current conditions.
  #
  # Matching prefers explicit weather description/condition text and falls back
  # to broad temperature buckets only when needed.
  #
  # @return [String] public asset path
  def background_image_path
    description_text = weather_text.to_s.downcase

    return "/weather/thunder.jpg" if description_text.match?(/thunder|storm/)
    return "/weather/snowing.jpg" if description_text.match?(/snow|sleet|blizzard|flurr/)
    return "/weather/cloudy-rain.jpg" if description_text.match?(/cloud|overcast|rain|drizzle|shower|mist|fog/)
    return "/weather/cold.jpg" if description_text.match?(/freeze|cold|snow/) && current_temp.to_f <= 32
    return "/weather/sunny.jpg" if description_text.match?(/sun|clear/)
    return "/weather/sunny.jpg" if current_temp.blank?
    return "/weather/hot.jpg" if current_temp.to_f >= 85
    return "/weather/freezing.jpg" if current_temp.to_f <= 20

    "/weather/sunny.jpg"
  end

  # @return [Array<Hash>]
  def days
    Array(forecast[:daily])
  end

  # Returns the best available short condition text from the payload.
  #
  # @return [String, nil]
  def weather_text
    forecast.dig(:current, :description) ||
      forecast.dig(:current, :condition) ||
      forecast.dig(:daily, 0, :description) ||
      forecast.dig(:daily, 0, :condition)
  end

  # @return [String, nil]
  def today_range
    today = days.first
    return if today.blank?

    "High #{Formatters::WeatherFormatter.temperature(today[:high])} / Low #{Formatters::WeatherFormatter.temperature(today[:low])}"
  end

  # @return [Array<DailyForecast>]
  def fallback_forecast
    7.times.map do |i|
      DailyForecast.new(
        label: (Date.current + i.days).strftime("%a"),
        summary: "No forecast data",
        high: "--",
        low: "--"
      )
    end
  end
end
