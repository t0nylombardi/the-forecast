# frozen_string_literal: true

class ForecastDashboardComponent < ViewComponent::Base
  def initialize(data:, alert: nil)
    @data = data
    @alert = alert
  end

  private

  attr_reader :data
  attr_reader :alert
end
