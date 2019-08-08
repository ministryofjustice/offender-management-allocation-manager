# frozen_string_literal: true

require 'csv'
require_relative '../../lib/delius/manual_extractor'
require_relative '../../lib/onboard_prison'

namespace :delius do
  desc 'Create CaseInformation records for a specific prison'
  task :onboard, [:prison, :file] => [:environment] do |_task, args|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    # Make sure both arguments are specified and bail if not
    Rails.logger.error('No prison specified') if args[:prison].blank?
    Rails.logger.error('No file specified') if args[:file].blank?
    next unless args[:file].present? && args[:prison].present?

    offender_ids = fetch_offenders(args[:prison])
    Rails.logger.info("Found #{offender_ids.count} for #{args[:prison]}")

    delius_records = load_delius_records(args[:file])
    Rails.logger.info("Found #{delius_records.count} in #{args[:file]}")

    op = OnboardPrison.new(args[:prison], offender_ids, delius_records)
    op.complete_missing_info

    Rails.logger.info("Processing resulted in #{op.additions} additions")
    Rails.logger.info("There were #{op.delius_missing} records unavailable in excel")
  end
end

def fetch_offenders(prison)
  OffenderService.get_offenders_for_prison(prison).map(&:offender_no)
end

def load_delius_records(file)
  Delius::ManualExtractor.new(file).fetch_records
end
