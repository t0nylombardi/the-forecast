# frozen_string_literal: true

# Renders the forecast dashboard and processes address-based forecast lookups.
#
# The controller keeps routing and response concerns here while delegating
# forecast retrieval to `Weather::ForecastService` and dashboard shaping to
# `ForecastDashboardPresenter`.
class ForecastsController < ApplicationController
  # Loads the dashboard for the best available address or ZIP code.
  #
  # Resolution order:
  # 1. Address submitted in the current request
  # 2. `address` or legacy `postal_code` in the root-route query string
  # 3. ZIP code inferred from the visitor IP address
  def index
    render_dashboard(selected_address)
  end

  # Handles address submissions from the dashboard search form.
  #
  # HTML requests use a PRG flow and redirect back to `root_path`, preserving
  # the ZIP code as a query parameter so refreshes do not resubmit PATCH.
  # Turbo Stream requests render the dashboard body directly.
  def update_forecast
    respond_to do |format|
      address = forecast_address
      result = fetch_forecast(address)

      format.html do
        flash[:alert] = result.error if result.failure?
        redirect_to root_path(address:)
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
      address: selected_address
    )

    if turbo
      render :index, formats: :html, status: status_for(result)
    else
      render :index, status: status_for(result)
    end
  end

  # @param address [String, nil]
  # @return [Result]
  def fetch_forecast(address)
    return Result.failure("Address with a 5-digit ZIP code is required") if address.blank?

    Result.success(Weather::ForecastService.call(address:))
  rescue Weather::ForecastService::Failure => e
    Result.failure(e.message)
  end

  # Strong params for the forecast form payload.
  #
  # @return [ActionController::Parameters]
  def forecast_params
    params.fetch(:forecast, {}).permit(:address, :postal_code)
  end

  # @return [String, nil]
  def forecast_address
    forecast_params[:address].presence || forecast_params[:postal_code]
  end

  # @param forecast [Hash, nil]
  # @param address [String, nil]
  # @return [ForecastDashboardPresenter::DashboardData]
  def dashboard_data_for(forecast:, address:)
    ForecastDashboardPresenter.new(
      forecast: forecast,
      address:
    ).dashboard_data
  end

  # @return [String, nil]
  def initial_postal_code
    Location::IpLookupService.call(ip_address: request.remote_ip)
  rescue Location::IpLookupService::Failure
    nil
  end

  # @return [String, nil]
  def selected_address
    forecast_address.presence || params[:address].presence || params[:postal_code].presence || initial_postal_code
  end

  # @param result [Result]
  # @return [Symbol]
  def status_for(result)
    result.failure? ? :unprocessable_content : :ok
  end
end
