# frozen_string_literal: true

desc 'Recalculate handover dates for all known offenders, and publishes an event to inform nDelius'
task recalculate_handover_dates: :environment do
  Rails.logger = Logger.new($stdout) if Rails.env.production?

  Rails.logger.info('Queueing RecalculateHandoverDateJob for all offenders')

  Prison.active.find_each do |prison|
    offender_ids = prison.offenders.map(&:offender_no)

    ActiveJob.perform_all_later(
      offender_ids.map { RecalculateHandoverDateJob.new(it) }
    )

    Rails.logger.info(
      "event=recalculate_handover_dates,prison=#{prison.code},queued=#{offender_ids.size}"
    )
  end

  Rails.logger.info('RecalculateHandoverDateJob all done')
end
