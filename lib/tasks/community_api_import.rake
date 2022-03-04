# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    Rails.logger = Logger.new($stdout)

    # Avoid filling up the in-memory SQL query cache – we're going to be reading lots of database records
    ActiveRecord::Base.connection.disable_query_cache!

    prison_count = Prison.all.count

    Prison.all.each_with_index do |prison, prison_index|
      prison_log_prefix = "[#{prison_index + 1}/#{prison_count}]"
      Rails.logger.info("#{prison_log_prefix} Getting offenders for prison #{prison.name} (#{prison.code})")

      offender_count = prison.all_policy_offenders.each { |offender|
        ProcessDeliusDataJob.perform_later offender.offender_no
        Rails.logger.info("#{prison_log_prefix} Queued job for offender #{offender.offender_no}")
      }.count

      Rails.logger.info("#{prison_log_prefix} Queued jobs for #{offender_count} offenders")
    end

    Rails.logger.info('Done')
  end
end
