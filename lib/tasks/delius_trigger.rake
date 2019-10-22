namespace :delius do
  desc 'Trigger CaseInformation records after changing auto-delius-import'
  task trigger: :environment do |_task|
    Rails.logger = Logger.new(STDOUT)

    Rails.logger.info("[DELIUS] Triggering caseinformation updates. Auto-delius? #{Flipflop.auto_delius_import?}")

    if Flipflop.auto_delius_import?
      DeliusData.find_each do |delius_record|
        ProcessDeliusDataJob.perform_later delius_record.noms_no
      end
    else
      (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').each do |prison|
        Rails.logger.info("[DELIUS] Creating jobs for #{prison}")

        counter = 0
        OffenderService.get_offenders_for_prison(prison).each do |offender|
          ProcessDeliusDataJob.perform_later offender.offender_no
          counter += 1
        end

        Rails.logger.info("[DELIUS] Created #{counter} jobs for #{prison}")
      end
    end
  end
end
