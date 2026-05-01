# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::AddressParser do
  describe ".postal_code" do
    it "extracts the canonical ZIP code from an address" do
      expect(described_class.postal_code("123 Main St, New York, NY 10001")).to eq("10001")
    end

    it "normalizes ZIP+4 input to the 5-digit ZIP used for caching" do
      expect(described_class.postal_code("Beverly Hills, CA 90210-1234")).to eq("90210")
    end

    it "returns nil when the address does not include a ZIP code" do
      expect(described_class.postal_code("New York, NY")).to be_nil
    end
  end
end
