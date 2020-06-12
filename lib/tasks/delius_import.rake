# frozen_string_literal: true

require_relative '../../lib/delius/extract_file_reader'

namespace :delius_etl do
  desc 'Loads delius information from a spreadsheet into DB and trigger'
  task :import_file, [:file] => [:environment] do |_task, args|
    Rails.logger = Logger.new(STDOUT)

    Rails.logger.error('No file specified during manual delius import') if args[:file].blank?
    next if args[:file].blank?

    changed_count = 0
    record_count = 0
    reader = Delius::ExtractFileReader.new(args[:file])
    reader.each do |record|
      if record[:noms_no].present?
        if DeliusDataService.upsert(record)
          changed_count += 1
        end
        print "\r#{changed_count}"
        $stdout.flush
      end
      record_count += 1
    end
    Rails.logger.info("#{record_count} Records processed #{changed_count} changed records")
  end
end
