# frozen_string_literal: true

class ForecastDashboardPresenter
  DailyForecast = Data.define(:label, :summary, :high, :low)
  SidebarInfo = Data.define(:location_name, :postal_code)
  Hero = Data.define(:title, :timestamp, :temperature, :description)
  DashboardData = Data.define(:search_value, :sidebar_info, :hero, :daily_forecast, :background_image_path)

  DEFAULT_DESCRIPTION = "Enter a valid US ZIP code to load the current weather and 7-day forecast."

  def initialize(forecast:, postal_code:)
    @forecast = forecast&.dig(:data) || forecast || {}
    @postal_code = postal_code
  end

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

  def sidebar_info
    SidebarInfo.new(
      location_name: location_name,
      postal_code: postal_code
    )
  end

  def hero
    Hero.new(
      title: location_name,
      timestamp: Formatters::WeatherFormatter.timestamp(current_time, postal_code:),
      temperature: Formatters::WeatherFormatter.temperature(current_temp),
      description: description
    )
  end

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

  def location_name
    [forecast.dig(:location, :name), forecast.dig(:location, :country)]
      .compact_blank
      .join(", ")
      .presence || "Unknown location"
  end

  def current_time
    forecast.dig(:current, :time)
  end

  def current_temp
    forecast.dig(:current, :temperature)
  end

  def description
    [
      current_description&.capitalize,
      today_range
    ].compact.join(". ").presence || DEFAULT_DESCRIPTION
  end

  def background_image_path
    description_text = current_description.to_s.downcase

    return "/weather/thunder.jpg" if description_text.match?(/thunder|storm/)
    return "/weather/snowing.jpg" if description_text.match?(/snow|sleet|blizzard|flurr/)
    return "/weather/cloudy-rain.jpg" if description_text.match?(/rain|drizzle|shower|mist|fog/)
    return "/weather/sunny.jpg" if description_text.match?(/sun|clear/)
    return "/weather/sunny.jpg" if current_temp.blank?
    return "/weather/hot.jpg" if current_temp.to_f >= 85
    return "/weather/freezing.jpg" if current_temp.to_f <= 20
    return "/weather/cold.jpg" if current_temp.to_f <= 45

    "/weather/sunny.jpg"
  end

  def days
    Array(forecast[:daily])
  end

  def current_description
    forecast.dig(:current, :description)
  end

  def today_range
    today = days.first
    return if today.blank?

    "High #{Formatters::WeatherFormatter.temperature(today[:high])} / Low #{Formatters::WeatherFormatter.temperature(today[:low])}"
  end

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
