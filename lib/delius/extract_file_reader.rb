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
      @spreadsheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
        next if row_is_empty?(row)

        record = map_row_to_fields(row)
        yield(record)
      end
    end

  private

    def map_row_to_fields(row)
      # Create an array of string values for the row object given
      # Empty cells (represented as `nil`) become empty strings
      values = row.map do |cell|
        if cell.nil?
          ''
        else
          cell.value.to_s
        end
      end

      FIELDS.zip(values).to_h
    end

    def row_is_empty?(row)
      row.filter(&:present?).empty?
    end
  end
end
