# frozen_string_literal: true

require 'nokogiri'
require_relative '../../lib/delius/processor'

namespace :delius_etl do
  desc 'Loads delius information from a spreadsheet into DB and trigger'
  task :import_file, [:file] => [:environment] do |_task, args|
    Rails.logger = Logger.new(STDOUT)

    Rails.logger.error('No file specified during manual delius import') if args[:file].blank?
    next if args[:file].blank?

    total = 0
    row_count = 0
    processor = Delius::Processor.new(args[:file])
    processor.each do |row|
      record = {}

      row.each_with_index do |val, idx|
        key = key_fields[idx]
        record[key] = val
      end

      if record[:noms_no].present?
        if DeliusDataService.upsert(record)
          total += 1
        end
        print "\r#{total}"
        $stdout.flush
      end
      row_count += 1
    end
    Rails.logger.info("#{row_count} Records processed #{total} changed records")
  end

  def key_fields
    @key_fields ||= [
      :crn, :pnc_no, :noms_no, :fullname, :tier, :roh_cds,
      :offender_manager, :org_private_ind, :org,
      :provider, :provider_code,
      :ldu, :ldu_code,
      :team, :team_code,
      :mappa, :mappa_levels, :date_of_birth
    ]
  end
end
