# frozen_string_literal: true

desc 'Recalculate handover dates for all known offenders, and push changes into nDelius'
task repush_all_handover_dates_to_delius: :environment do
  Rails.logger = Logger.new($stdout)
  Rails.logger.info 'Invoking rake task :recalculate_handover_dates'
  RepushAllHandoverDatesToDeliusJob.perform_later
end
