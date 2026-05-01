# frozen_string_literal: true

require "ipaddr"

module Location
  class IpLookupService
    LOOKUP_URL = "http://ip-api.com/json"
    FALLBACK_IP = "69.118.160.235"
    FIELDS = "status,zip"
    TIMEOUT_SECONDS = 5

    class Failure < StandardError; end

    def self.call(ip_address:)
      new(ip_address:).call
    end

    def initialize(ip_address:, client: HTTParty)
      @ip_address = resolved_ip(ip_address)
      @client = client
    end

    def call
      response = client.get(
        "#{LOOKUP_URL}/#{ip_address}",
        query: {fields: FIELDS},
        timeout: TIMEOUT_SECONDS
      )

      payload = JSON.parse(response.body)

      raise Failure, "IP lookup failed" unless response.success?
      raise Failure, "IP lookup failed" unless payload["status"] == "success"
      raise Failure, "ZIP code unavailable" if payload["zip"].blank?

      payload["zip"]
    rescue JSON::ParserError
      raise Failure, "IP lookup failed"
    end

    private

    attr_reader :ip_address, :client

    def resolved_ip(candidate)
      return FALLBACK_IP if candidate.blank?

      parsed = IPAddr.new(candidate)
      return FALLBACK_IP if parsed.loopback? || parsed.private?

      candidate
    rescue IPAddr::InvalidAddressError
      FALLBACK_IP
    end
  end
end
