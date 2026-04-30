# frozen_string_literal: true

require "rails_helper"

RSpec.describe Location::IpLookupService do
  describe ".call" do
    it "returns the zip code from the API response and falls back for local IPs" do
      requested_url = nil
      requested_query = nil
      requested_timeout = nil

      allow(HTTParty).to receive(:get) do |url, query:, timeout:|
        requested_url = url
        requested_query = query
        requested_timeout = timeout
        TestResponse.new(body: {status: "success", zip: "10598"}.to_json, success?: true)
      end

      result = described_class.call(ip_address: "127.0.0.1")

      expect(result).to eq("10598")
      expect(requested_url).to eq("http://ip-api.com/json/69.118.160.235")
      expect(requested_query).to eq(fields: "status,zip")
      expect(requested_timeout).to eq(5)
    end

    it "raises when the API does not return a zip code" do
      allow(HTTParty).to receive(:get)
        .and_return(TestResponse.new(body: {status: "success", zip: nil}.to_json, success?: true))

      expect { described_class.call(ip_address: "69.118.160.235") }
        .to raise_error(described_class::Failure, "ZIP code unavailable")
    end
  end
end
