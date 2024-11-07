# frozen_string_literal: true

desc 'Recalculate handover dates for all known offenders, and publishes an event to inform nDelius'
task recalculate_handover_dates: :environment do
  Rails.logger = Logger.new($stdout) if Rails.env.production?

  Rails.logger.info('Queueing RecalculateHandoverDateJob for all offenders')

  Prison.all.find_each do |prison|
    prison.allocatable_offenders.each do |offender|
      RecalculateHandoverDateJob.perform_later(offender.offender_no)
    end
    Rails.logger.info("RecalculateHandoverDateJob #{prison.name} Queued #{prison.allocatable_offenders.count} Jobs")
  end

  Rails.logger.info('RecalculateHandoverDateJob all done')
end
