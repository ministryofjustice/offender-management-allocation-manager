# frozen_string_literal: true

require 'nokogiri'
require_relative '../../lib/delius/processor'

namespace :delius do
  desc 'Generates stats from the latest XLSX file'
  task :stats, [:file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No file specified') if args[:file].blank?
    next if args[:file].blank?

    total_rows = 0
    total_missing_tier = 0
    total_missing_noms_no = 0
    duplicate_noms_nos = []

    seen_noms_nos = {}

    processor = Delius::Processor.new(args[:file])
    processor.each do |row|
      record = {}

      row.each_with_index do |val, idx|
        key = fields[idx]
        record[key] = val
      end

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

      total_rows += 1
    end

    puts "Total number of rows: #{total_rows}"
    puts "Number missing a tier: #{total_missing_tier}"
    puts "Number without noms no: #{total_missing_noms_no}"
    puts "Multi-use noms no count: #{duplicate_noms_nos.count}"
    puts "Multi-use noms no: #{duplicate_noms_nos}"
  end

  def fields
    @fields ||= [
      :crn, :pnc_no, :noms_no, :fullname, :tier, :roh_cds,
      :offender_manager, :org_private_ind, :org,
      :provider, :provider_code,
      :ldu, :ldu_code,
      :team, :team_code,
      :mappa, :mappa_levels
    ]
  end
end
