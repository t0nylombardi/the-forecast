# frozen_string_literal: true

class ForecastsController < ApplicationController
  def index
    render_dashboard(initial_postal_code)
  end

  def update_forecast
    respond_to do |format|
      result = fetch_forecast(forecast_params[:postal_code])

      format.html do
        render_dashboard_from_result(result)
      end

      format.turbo_stream do
        render_dashboard_from_result(result, turbo: true)
      end
    end
  end

  private

  def render_dashboard(postal_code)
    result = fetch_forecast(postal_code)
    render_dashboard_from_result(result)
  end

  def render_dashboard_from_result(result, turbo: false)
    if result.failure?
      flash.now[:alert] = result.error
    end

    @dashboard_data = dashboard_data_for(
      forecast: result.data,
      postal_code: forecast_params[:postal_code]
    )

    render :index, status: status_for(result)
  end

  def fetch_forecast(postal_code)
    return Result.failure("Postal code is required") if postal_code.blank?

    data = Weather::ForecastService.call(postal_code:)
    Result.success(data)
  rescue Weather::ForecastService::Failure => e
    Result.failure(e.message)
  end

  def forecast_params
    params.fetch(:forecast, {}).permit(:postal_code)
  end

  def dashboard_data_for(forecast:, postal_code:)
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

  def status_for(result)
    result.failure? ? :unprocessable_content : :ok
  end
end
