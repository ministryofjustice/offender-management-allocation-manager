# frozen_string_literal: true

desc 'Recalculate handover dates for all known offenders, and push changes into nDelius'
task recalculate_handover_dates: :environment do |_task|
  Rails.logger = Logger.new(STDOUT)

  count = CaseInformation.count

  Rails.logger.info("Queueing jobs for #{count} offenders")

  CaseInformation.find_each.with_index do |case_info, index|
    RecalculateHandoverDateJob.perform_later(case_info.nomis_offender_id)
    Rails.logger.info("[#{index + 1}/#{count}] Queued #{case_info.nomis_offender_id}")
  end

  Rails.logger.info('Done')
end
