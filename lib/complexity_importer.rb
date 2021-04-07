# frozen_string_literal: true

require 'csv'

class ComplexityImporter
  NOMS_HEADER = 'NOMS No'
  COMPLEXITY_HEADER = 'Complexity Score Band'

  class << self
    def import(stream)
      CSV.new(stream, headers: true).each do |row|
        offender_no = row.fetch(NOMS_HEADER)
        complexity = row.fetch(COMPLEXITY_HEADER).downcase

        next if complexity == 'unassessed' # skip these rows

        HmppsApi::ComplexityApi.save offender_no, level: complexity, reason: nil, username: nil
      end
    end
  end
end
