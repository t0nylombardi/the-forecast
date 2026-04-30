# frozen_string_literal: true

class ForecastDashboardPresenter
  DailyForecast = Data.define(:label, :summary, :high, :low)
  SidebarInfo = Data.define(:location_name, :postal_code)
  Hero = Data.define(:title, :timestamp, :temperature, :description)
  DashboardData = Data.define(
    :search_value,
    :sidebar_info,
    :hero,
    :daily_forecast
  )

  DEFAULT_TITLE = "Forecast"
  DEFAULT_TIMESTAMP = "Weather data unavailable"
  DEFAULT_DESCRIPTION = "Enter a valid US ZIP code to load the current weather and 7-day forecast."

  def initialize(forecast:, postal_code: nil)
    @forecast = forecast&.deep_symbolize_keys || {}
    @forecast_data = @forecast[:data] || @forecast
    @postal_code = postal_code.presence || @forecast_data.dig(:location, :postal_code)
  end

  def dashboard_data
    DashboardData.new(
      search_value: postal_code.to_s,
      sidebar_info: sidebar_info,
      hero: hero,
      daily_forecast: daily_forecast
    )
  end

  private

  attr_reader :forecast_data, :postal_code

  def sidebar_info
    SidebarInfo.new(
      location_name: location_name,
      postal_code: postal_code
    )
  end

  def hero
    Hero.new(
      title: hero_title,
      timestamp: formatted_timestamp,
      temperature: formatted_temperature(current_temperature),
      description: current_description
    )
  end

  def daily_forecast
    return fallback_daily_forecast if forecast_days.empty?

    forecast_days.first(7).map do |day|
      DailyForecast.new(
        label: formatted_day_label(day[:date]),
        summary: day[:description].to_s.capitalize,
        high: formatted_temperature(day[:high]),
        low: formatted_temperature(day[:low])
      )
    end
  end

  def location_name
    [forecast_data.dig(:location, :name), forecast_data.dig(:location, :country)].compact_blank.join(", ").presence || "Unknown location"
  end

  def hero_title
    location_name.presence || DEFAULT_TITLE
  end

  def formatted_timestamp
    current_time = forecast_data.dig(:current, :time)
    return DEFAULT_TIMESTAMP unless current_time.respond_to?(:strftime)

    [
      postal_code.presence,
      current_time.strftime("%A, %b %-d, %Y, %-I:%M%p")
    ].compact.join(" · ")
  end

  def current_temperature
    forecast_data.dig(:current, :temperature)
  end

  def current_description
    details = []
    details << forecast_data.dig(:current, :description).to_s.capitalize.presence
    details << today_temperature_range
    details.compact.join(". ").presence || DEFAULT_DESCRIPTION
  end

  def forecast_days
    Array(forecast_data[:daily])
  end

  def fallback_daily_forecast
    7.times.map do |index|
      DailyForecast.new(
        label: (Date.current + index.days).strftime("%a"),
        summary: "No forecast data",
        high: "--",
        low: "--"
      )
    end
  end

  def formatted_day_label(date)
    return date.strftime("%a") if date.respond_to?(:strftime)

    date.to_s
  end

  def formatted_temperature(value)
    return "--" if value.blank?

    "#{value.round}°"
  end

  def today_temperature_range
    today = forecast_days.first
    return if today.blank?

    "High #{formatted_temperature(today[:high])} / Low #{formatted_temperature(today[:low])}"
  end
end
