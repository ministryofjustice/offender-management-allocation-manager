# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    Rails.logger = Logger.new(STDOUT)

    # This query is an alias for 'all active prisons'
    Allocation.distinct.pluck(:prison).map { |p| Prison.new(p) }.each do |prison|
      prison.offenders.each do |offender|
        ProcessDeliusDataJob.perform_later offender.nomis_offender_id
      end
    end
  end
end
