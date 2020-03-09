# frozen_string_literal: true

require 'csv'

module Delius
  class ManualExtractor
    # rubocop:disable Layout/LineLength
    HEADER_CELLS = ['CRN', 'PNC No', 'NOMS No', 'Fullname (O)', 'Tier Cd (OMT)', 'Risk Of Harm Cds', 'Offender Manager', 'Organisation Private Ind (OfM)', 'Organisation (OfM)', 'Provider (OfM)', 'Provider Cd (OfM)', 'LDU (OfM)', 'LDU Cd (OfM)', 'Team (OfM)', 'Team Cd (OfM)', 'MAPPA Y/N', 'MAPPA Levels', 'Birth Dt (O)'].freeze
    MAPPED_CELLS = %w[crn pnc_no noms_no fullname tier roh_cds offender_manager org_private_ind org provider provider_cd ldu ldu_cd team team_cd mappa mappa_levels date_of_birth].freeze
    # rubocop:enable Layout/LineLength

    attr_reader :errors

    def initialize(filename)
      @filename = filename
      @errors = []
    end

    def fetch_records
      records = []

      validated_header = false
      CSV.foreach(@filename, skip_blanks: true) do |row|
        unless validated_header
          validated_header = validate_header(row)
          next
        end

        next if row.count == 0 || row[2].blank?

        record = {
          noms_no: row[2],
          tier: row[4].present? ? row[4][0] : '',
          provider_cd: row[10][0] == 'C' ? 'CRC' : 'NPS',
          welsh_offender: row[12].start_with?('WPT'),
          crn: row[0]
        }

        records << record if clean_record(record)
      end
      records
    end

  private

    def validate_header(row)
      row.map(&:strip) == HEADER_CELLS
    end

    def clean_record(record)
      if record[:tier].blank?
        # Fill in @errors with a proper error
        @errors << 'Bad record passed, missing tier'
        return false
      end

      true
    end
  end
end
