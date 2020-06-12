# frozen_string_literal: true

require_relative '../../lib/delius/extract_file_reader'

namespace :delius_etl do
  desc 'Generates stats from the latest XLSX file'
  task :stats, [:file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No file specified') if args[:file].blank?
    next if args[:file].blank?

    total_records = 0
    total_missing_tier = 0
    total_missing_noms_no = 0
    duplicate_noms_nos = []

    seen_noms_nos = {}

    reader = Delius::ExtractFileReader.new(args[:file])
    reader.each do |record|
      if record[:noms_no].present? && seen_noms_nos.key?(record[:noms_no])
        duplicate_noms_nos << record[:noms_no]
      else
        seen_noms_nos[record[:noms_no]] = 1
      end

      if record[:tier].blank? || record[:tier].strip.blank?
        total_missing_tier += 1
      end

      if record[:noms_no].blank?
        total_missing_noms_no += 1
      end

      total_records += 1
    end

    puts "Total number of records: #{total_records}"
    puts "Number missing a tier: #{total_missing_tier}"
    puts "Number without noms no: #{total_missing_noms_no}"
    puts "Multi-use noms no count: #{duplicate_noms_nos.count}"
    puts "Multi-use noms no: #{duplicate_noms_nos}"
  end
end
