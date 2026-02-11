# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    $stdout.sync = true
    Rails.logger = Logger.new($stdout)

    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    prison_count = Prison.count

    Prison.order(code: :asc).each.with_index(1) do |prison, index|
      offender_nos = OmicEligibility.eligible.where(prison: prison.code).pluck(:nomis_offender_id)
      ProcessDeliusDataJob.perform_later(offender_nos)

      Rails.logger.warn(
        "[#{index}/#{prison_count}] Queued job for #{offender_nos.count} offenders in #{prison.code}"
      )
    end

    Rails.logger.warn('Done')
  end
end
