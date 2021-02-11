# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    Rails.logger = Logger.new(STDOUT)

    # Avoid filling up the in-memory SQL query cache – we're going to be reading lots of database records
    ActiveRecord::Base.connection.disable_query_cache!

    prison_count = Prison.active.count

    Prison.active.each_with_index do |prison, prison_index|
      prison_log_prefix = "[#{prison_index + 1}/#{prison_count}]"
      Rails.logger.info("#{prison_log_prefix} Getting offenders for prison #{prison.name} (#{prison.code})")

      offenders = prison.offenders
      offender_count = offenders.count

      Rails.logger.info("#{prison_log_prefix} Queueing jobs for #{offender_count} offenders")

      offenders.each_with_index do |offender, offender_index|
        ProcessDeliusDataJob.perform_later offender.offender_no
        offender_log_prefix = "[#{offender_index + 1}/#{offender_count}]"
        Rails.logger.info("#{prison_log_prefix} #{offender_log_prefix} Queued #{offender.offender_no}")
      end
    end

    Rails.logger.info('Done')
  end
end
