# frozen_string_literal: true

module ForecastDashboard
  class HeroComponent < ViewComponent::Base
    def initialize(hero:)
      @hero = hero
    end

    private

    attr_reader :hero
  end
end
