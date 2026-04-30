# frozen_string_literal: true

# Renders the forecast dashboard and processes ZIP-code lookups.
#
# The controller keeps routing and response concerns here while delegating
# forecast retrieval to `Weather::ForecastService` and dashboard shaping to
# `ForecastDashboardPresenter`.
class ForecastsController < ApplicationController
  # Loads the dashboard for the best available ZIP code.
  #
  # Resolution order:
  # 1. ZIP code submitted in the current request
  # 2. `postal_code` in the root-route query string
  # 3. ZIP code inferred from the visitor IP address
  def index
    render_dashboard(selected_postal_code)
  end

  # Handles ZIP-code submissions from the dashboard search form.
  #
  # HTML requests use a PRG flow and redirect back to `root_path`, preserving
  # the ZIP code as a query parameter so refreshes do not resubmit PATCH.
  # Turbo Stream requests render the dashboard body directly.
  def update_forecast
    respond_to do |format|
      postal_code = forecast_postal_code
      result = fetch_forecast(postal_code)

      format.html do
        flash[:alert] = result.error if result.failure?
        redirect_to root_path(postal_code:)
      end

      format.turbo_stream do
        render_dashboard_from_result(result, turbo: true)
      end
    end
  end

  private

  # @param postal_code [String, nil]
  def render_dashboard(postal_code)
    result = fetch_forecast(postal_code)
    render_dashboard_from_result(result)
  end

  # @param result [Result]
  # @param turbo [Boolean]
  def render_dashboard_from_result(result, turbo: false)
    flash.now[:alert] = result.error if result.failure?

    @dashboard_data = dashboard_data_for(
      forecast: result.data,
      postal_code: selected_postal_code
    )

    if turbo
      render :index, formats: :html, status: status_for(result)
    else
      render :index, status: status_for(result)
    end
  end

  # @param postal_code [String, nil]
  # @return [Result]
  def fetch_forecast(postal_code)
    return Result.failure("Postal code is required") if postal_code.blank?

    data = Weather::ForecastService.call(postal_code:)[:data]
    Result.success(data)
  rescue Weather::ForecastService::Failure => e
    Result.failure(e.message)
  end

  # Strong params for the forecast form payload.
  #
  # @return [ActionController::Parameters]
  def forecast_params
    params.fetch(:forecast, {}).permit(:postal_code)
  end

  # @return [String, nil]
  def forecast_postal_code
    forecast_params[:postal_code]
  end

  # @param forecast [Hash, nil]
  # @param postal_code [String, nil]
  # @return [ForecastDashboardPresenter::DashboardData]
  def dashboard_data_for(forecast:, postal_code:)
    ForecastDashboardPresenter.new(
      forecast: forecast,
      postal_code:
    ).dashboard_data
  end

  # @return [String, nil]
  def initial_postal_code
    Location::IpLookupService.call(ip_address: request.remote_ip)
  rescue Location::IpLookupService::Failure
    nil
  end

  # @return [String, nil]
  def selected_postal_code
    forecast_postal_code.presence || params[:postal_code].presence || initial_postal_code
  end

  # @param result [Result]
  # @return [Symbol]
  def status_for(result)
    result.failure? ? :unprocessable_content : :ok
  end
end
