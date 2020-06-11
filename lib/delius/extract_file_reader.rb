# frozen_string_literal: true

require 'roo'

module Delius
  class ExtractFileReader
    include Enumerable

    FIELDS = [
      :crn, :pnc_no, :noms_no, :fullname, :tier, :roh_cds,
      :offender_manager, :org_private_ind, :org,
      :provider, :provider_code,
      :ldu, :ldu_code,
      :team, :team_code,
      :mappa, :mappa_levels, :date_of_birth
    ].freeze

    def initialize(filename)
      @spreadsheet = Roo::Spreadsheet.open(filename, extension: :xlsx)
    end

    def each
      @spreadsheet.each_row_streaming(offset: 1) do |row|
        record = map_row_to_fields(row)
        yield(record)
      end
    end

  private

    def map_row_to_fields(row)
      values = row.map { |r| r.value.to_s }
      FIELDS.zip(values).to_h
    end
  end
end
