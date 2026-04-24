require "test_helper"

module Weather
  class ForecastServiceTest < ActiveSupport::TestCase
    Response = Struct.new(:parsed_response, :success?)

    test ".call fetches a forecast using the ZIP code when present" do
      response = Response.new({"location" => {"name" => "Brooklyn"}}, true)
      received_query = nil

      stub_singleton_method(ForecastService, :get, ->(_path, query:) {
        received_query = query
        response
      }) do
        result = ForecastService.call(location: "Brooklyn", zip_code: "11201")

        assert_equal "11201", received_query[:q]
        assert_equal "Brooklyn", result.dig("location", "name")
      end
    end

    test ".call falls back to location when ZIP code is blank" do
      response = Response.new({"location" => {"name" => "Austin"}}, true)
      received_query = nil

      stub_singleton_method(ForecastService, :get, ->(_path, query:) {
        received_query = query
        response
      }) do
        result = ForecastService.call(location: "Austin, TX", zip_code: "")

        assert_equal "Austin, TX", received_query[:q]
        assert_equal "Austin", result.dig("location", "name")
      end
    end

    test ".call returns a normalized error payload for failed responses" do
      response = Response.new({"error" => {"message" => "Invalid request"}}, false)
      received_query = nil

      stub_singleton_method(ForecastService, :get, ->(_path, query:) {
        received_query = query
        response
      }) do
        result = ForecastService.call(location: "Chicago", zip_code: "60601")

        assert_equal "60601", received_query[:q]
        assert_equal({"error" => {"message" => "Invalid request"}}, result)
      end
    end

    test ".call returns a generic error when the HTTP request raises" do
      received_query = nil

      stub_singleton_method(ForecastService, :get, ->(_path, query:) {
        received_query = query
        raise Timeout::Error
      }) do
        result = ForecastService.call(location: "Seattle", zip_code: nil)

        assert_equal "Seattle", received_query[:q]
        assert_equal(
          {"error" => {"message" => "Unable to fetch forecast right now."}},
          result
        )
      end
    end
  end
end
