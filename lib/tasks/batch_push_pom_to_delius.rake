namespace :batch_push_pom_to_delius do
  desc 'batch push pom to delius job'
  task populate_delius: :environment do
    Rails.logger = Logger.new($stdout)

    records = AllocationHistory.where.not(primary_pom_nomis_id: nil)

    count = records.count

    Rails.logger.info("Queueing jobs for #{count} offenders")

    records.find_each.with_index do |allocation, index|
      PushPomToDeliusJob.perform_later(allocation)
      Rails.logger.info("[#{index + 1}/#{count}] Queued #{allocation.nomis_offender_id}")
    end

    Rails.logger.info('Done')
  end
end
