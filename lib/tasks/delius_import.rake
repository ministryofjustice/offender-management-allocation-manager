# frozen_string_literal: true

require 'nokogiri'
require_relative '../../lib/delius/processor'

namespace :delius_import do
  desc 'Loads delius information from a spreadsheet into the DB'
  task :load, [:file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.error('No file specified') if args[:file].blank?
    next if args[:file].blank?

    total = 0
    processor = Delius::Processor.new(args[:file])
    processor.run { |row|
      record = {}

      row.each_with_index do |val, idx|
        key = fields[idx]
        record[key] = val
      end
      record[:tier] = record[:tier].present? ? record[:tier][0] : ''

      if record[:noms_no].present?
        DeliusData.upsert(record)
        print "\r#{total}"
        $stdout.flush
        total += 1
      end
    }
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
