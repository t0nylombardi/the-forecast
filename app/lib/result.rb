# frozen_string_literal: true

# Minimal success/failure wrapper used at controller boundaries.
class Result
  # @return [Object, nil]
  attr_reader :data, :error

  # @param data [Object]
  # @return [Result]
  def self.success(data)
    new(data:, error: nil)
  end

  # @param error [String]
  # @return [Result]
  def self.failure(error)
    new(data: nil, error:)
  end

  # @param data [Object, nil]
  # @param error [String, nil]
  def initialize(data:, error:)
    @data = data
    @error = error
  end

  # @return [Boolean]
  def success?
    error.nil?
  end

  # @return [Boolean]
  def failure?
    !success?
  end
end
