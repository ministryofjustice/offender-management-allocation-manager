namespace :delius do
  desc 'Trigger CaseInformation records afer changing auto-delius-import'
  task :trigger, :environment do |_task|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').each do |prison|
      OffenderService.get_offenders_for_prison(prison).each do |offender|
        ProcessDeliusDataJob.perform_later offender.offender_no
      end
    end
  end
end
