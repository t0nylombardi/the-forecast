# frozen_string_literal: true

class Result
  attr_reader :data, :error

  def self.success(data)
    new(data:, error: nil)
  end

  def self.failure(error)
    new(data: nil, error:)
  end

  def initialize(data:, error:)
    @data = data
    @error = error
  end

  def success?
    error.nil?
  end

  def failure?
    !success?
  end
end
