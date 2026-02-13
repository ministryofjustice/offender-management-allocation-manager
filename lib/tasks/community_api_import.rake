# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    # avoid lots of log traces from the API calls
    Rails.logger.level = :warn

    # Minimum ideal job size. We prefer to keep jobs above this size, even if it means
    # making them larger than this target (up to < 2x).
    # E.g. with 400: 600 offenders -> 1 job. 850 offenders -> 2 jobs.
    min_job_size = 400

    prison_count = Prison.count

    Prison.order(code: :asc).each.with_index(1) do |prison, index|
      offender_nos = OmicEligibility.eligible.where(prison: prison.code).pluck(:nomis_offender_id)

      batch_count = offender_nos.count / min_job_size
      batch_count = 1 if batch_count.zero? && offender_nos.any?

      if batch_count > 0
        offender_nos.in_groups(batch_count, false) do |batch|
          ProcessDeliusDataJob.perform_later(batch)
        end
      end

      puts "[CommunityApiImport] [#{index}/#{prison_count}] Queued #{offender_nos.count} offenders in #{prison.code} in #{batch_count} jobs"
    end
  end
end
