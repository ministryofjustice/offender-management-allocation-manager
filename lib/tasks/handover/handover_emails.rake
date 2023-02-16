namespace :handover do
  desc 'Send all handover reminders for today where the handover case has entered the 8 week window before handover'
  task send_all_upcoming_handover_window: :environment do
    Rails.logger = Logger.new($stdout)
    Handover::HandoverEmailBatchRun.send_all_upcoming_handover_window
  end

  desc 'Send all handover reminders for today to start handover - the handover date is here and a COM is allocated'
  task send_all_handover_date: :environment do
    Rails.logger = Logger.new($stdout)
    Handover::HandoverEmailBatchRun.send_all_handover_date
  end

  desc 'Send all handover reminders for today where we are 14 days past handover without a COM being allocated'
  task send_all_com_allocation_overdue: :environment do
    Rails.logger = Logger.new($stdout)
    Handover::HandoverEmailBatchRun.send_all_com_allocation_overdue
  end
end
