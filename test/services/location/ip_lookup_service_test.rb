# frozen_string_literal: true

require "test_helper"

module Location
  class IpLookupServiceTest < ActiveSupport::TestCase
    Response = Struct.new(:body, :success?)

    test ".call returns the zip code from the API response" do
      requested_url = nil
      requested_query = nil
      requested_timeout = nil

      stub_singleton_method(HTTParty, :get, ->(url, query:, timeout:) {
        requested_url = url
        requested_query = query
        requested_timeout = timeout

        Response.new({status: "success", zip: "10598"}.to_json, true)
      }) do
        assert_equal "10598", IpLookupService.call(ip_address: "127.0.0.1")
      end

      assert_equal "http://ip-api.com/json/69.118.160.235", requested_url
      assert_equal({fields: "status,zip"}, requested_query)
      assert_equal 5, requested_timeout
    end

    test ".call raises when the API does not return a zip code" do
      stub_singleton_method(HTTParty, :get, ->(*, **) {
        Response.new({status: "success", zip: nil}.to_json, true)
      }) do
        error = assert_raises(IpLookupService::Failure) { IpLookupService.call(ip_address: "69.118.160.235") }

        assert_equal "ZIP code unavailable", error.message
      end
    end
  end
end
