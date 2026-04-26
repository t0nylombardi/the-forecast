class ForecastsController < ApplicationController
  def index
    @forecast = nil
  end

  def update_forecast
    @forecast = fetch_weather_data
    handle_failed_fetch(@forecast) if @forecast["error"].present?

    respond_to do |format|
      format.html { render :index, status: forecast_status(@forecast) }
      format.turbo_stream { render :index, status: forecast_status(@forecast) }
    end
  end

  private

  def forecast_params
    params.permit(:location, :postal_code)
  end

  def fetch_weather_data
    Weather::ForecastService.call(
      location: forecast_params[:location],
      postal_code: forecast_params[:postal_code]
    )
  rescue Weather::ForecastService::Failure => e
    {"error" => {"message" => e.message}}
  end

  def handle_failed_fetch(forecast)
    flash.now[:alert] = forecast.dig("error", "message")
  end

  def forecast_status(forecast)
    forecast["error"].present? ? :unprocessable_entity : :ok
  end
end
