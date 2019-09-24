# frozen_string_literal: true

require 'csv'

class LDUEmailImporter
  def self.import(filename)
    CSV.read(filename, headers: true).each do |row|
      code = row[0]&.strip
      address = row[1]&.strip

      next if address.blank?

      LocalDivisionalUnit.find_by(code: code)&.update!(email_address: address)
    end
  end
end
