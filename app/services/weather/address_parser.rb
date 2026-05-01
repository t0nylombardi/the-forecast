# frozen_string_literal: true

module Weather
  # Extracts the cacheable US ZIP code from user-supplied address text.
  #
  # The assignment asks for address input while also requiring cache identity by
  # ZIP code. This parser keeps that rule explicit: any submitted address must
  # include a ZIP or ZIP+4, and the rest of the weather flow uses the canonical
  # 5-digit ZIP.
  class AddressParser
    ZIP_CODE_PATTERN = /\b\d{5}(?:-\d{4})?\b/

    def self.postal_code(value)
      value.to_s[ZIP_CODE_PATTERN]&.first(5)
    end
  end
end
