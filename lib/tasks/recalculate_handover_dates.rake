# frozen_string_literal: true

desc 'Recalculate handover dates for all known offenders, and push changes into nDelius'
task recalculate_handover_dates: :environment do |_task|
  Rails.logger = Logger.new(STDOUT)

  Rails.logger.info('Queueing RecalculateHandoverDateJob for all offenders')

  Prison.all.each do |prison|
    prison.offenders.each do |offender|
      RecalculateHandoverDateJob.perform_later(offender.nomis_offender_id)
      Rails.logger.info("RecalculateHandoverDateJob #{prison.name} Queued #{offender.nomis_offender_id}")
    end
  end

  Rails.logger.info('RecalculateHandoverDateJob all done')
end
