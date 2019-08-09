namespace :delius do
  desc 'Trigger CaseInformation records after changing auto-delius-import'
  task :trigger do |_task|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    (ENV['AUTO_DELIUS_IMPORT'] || '').split(',').each do |prison|
      OffenderService.get_offenders_for_prison(prison).each do |offender|
        ProcessDeliusDataJob.perform_later offender.offender_no
      end
    end
  end

  # it seems that we can't check Flipflop settings in rake tasks
  # so this task is needed once the feature goes completely live
  desc 'Trigger all CaseInformation records after enabling switch'
  task :trigger_all do |_task|
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    DeliusData.find_each do |delius_record|
      ProcessDeliusDataJob.perform_later delius_record.noms_no
    end
  end
end
