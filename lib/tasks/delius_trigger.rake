namespace :delius do
  desc 'Trigger CaseInformation records after changing auto-delius-import'
  task trigger: :environment do |_task|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    if Flipflop.auto_delius_import?
      DeliusData.find_each do |delius_record|
        ProcessDeliusDataJob.perform_later delius_record.noms_no
      end
    else
      (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').each do |prison|
        OffenderService::List.call(prison).each do |offender|
          ProcessDeliusDataJob.perform_later offender.offender_no
        end
      end
    end
  end
end
