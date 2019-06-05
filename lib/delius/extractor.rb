require 'roo'

module Delius
  class Extractor
    # rubocop:disable Metrics/LineLength
    HEADER_CELLS = ['CRN', 'PNC No', 'NOMS No', 'Fullname (O)', 'Tier Cd (OMT)', 'Risk Of Harm Cds', 'Offender Manager', 'Organisation Private Ind (OfM)', 'Organisation (OfM)', 'Provider (OfM)', 'Provider Cd (OfM)', 'LDU (OfM)', 'LDU Cd (OfM)', 'Team (OfM)', 'Team Cd (OfM)', 'MAPPA Y/N', 'MAPPA Levels'].freeze
    MAPPED_CELLS = %w[crn pnc_no noms_no fullname tier roh_cds offender_manager org_private_ind org provider provider_cd ldu ldu_cd team team_cd mappa mappa_levels].freeze
    # rubocop:enable Metrics/LineLength

    attr_reader :errors

    def initialize(filename)
      @filename = filename
      @errors = []
    end

    # rubocop:disable Metrics/MethodLength
    def fetch_records
      xlsx = Roo::Spreadsheet.open(@filename)
      records = []

      validated_header = false
      xlsx.each_row_streaming(pad_cells: true) do |row|
        unless validated_header
          validated_header = validate_header(row)
          next
        end

        record = {
          'timestamp' => Time.zone.now.getutc
        }

        next if row.count == 0

        row.each_with_index do |cell, i|
          next if cell.nil?

          k = MAPPED_CELLS[i]
          v = cell.value.to_s.strip
          record[k] = v
        end

        records << record if clean_record(record)
      end
      records
    end
  # rubocop:enable Metrics/MethodLength

  private

    def validate_header(row)
      row.map { |c| c.value.strip } == HEADER_CELLS
    end

    def clean_record(record)
      if record['tier'].nil?
        # Fill in @errors with a proper error
        @errors << 'Bad record passed, missing tier'
        return false
      end

      record['tier'] = record['tier'][0]
      record['provider_cd'] = record['provider_cd'] == 'C' ? 'CRC' : 'NPS'
      record['omicable'] = record['ldu_cd'].start_with?('WPT')
      true
    end

    def values_for_row(row, escape_func)
      MAPPED_CELLS.each_with_object([]) do |cell_label, lst|
        v = row[cell_label]
        lst << "'#{escape_func.call(v)}'"
      end.join(', ')
    end
  end
end
