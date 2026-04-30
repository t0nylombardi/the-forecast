class ForecastsController < ApplicationController
  def index
    postal_code = initial_postal_code
    @forecast = fetch_weather_data(postal_code:)
    handle_failed_fetch(@forecast) if forecast_error(@forecast).present?
    @dashboard_data = dashboard_data_for(forecast: @forecast, postal_code:)
  end

  def update_forecast
    postal_code = forecast_params[:postal_code]
    @forecast = fetch_weather_data(postal_code:)
    handle_failed_fetch(@forecast) if forecast_error(@forecast).present?
    @dashboard_data = dashboard_data_for(forecast: @forecast, postal_code:)

    respond_to do |format|
      format.html { render :index, status: forecast_status(@forecast) }
      format.turbo_stream { render :index, formats: :html, status: forecast_status(@forecast) }
    end
  end

  private

  def forecast_params
    params.fetch(:forecast, {}).permit(:postal_code)
  end

  def fetch_weather_data(postal_code:)
    return {"error" => {"message" => "Postal code is required"}} if postal_code.blank?

    Weather::ForecastService.call(postal_code:)
  rescue Weather::ForecastService::Failure => e
    {"error" => {"message" => e.message}}
  end

  def handle_failed_fetch(forecast)
    flash.now[:alert] = forecast_error(forecast)
  end

  def forecast_status(forecast)
    forecast_error(forecast).present? ? :unprocessable_content : :ok
  end

  def dashboard_data_for(forecast: nil, postal_code: nil)
    ForecastDashboardPresenter.new(
      forecast: forecast,
      postal_code:
    ).dashboard_data
  end

  def initial_postal_code
    Location::IpLookupService.call(ip_address: request.remote_ip)
  rescue Location::IpLookupService::Failure
    nil
  end

  def forecast_error(forecast)
    forecast&.dig("error", "message") || forecast&.dig(:error, :message)
  end
end
