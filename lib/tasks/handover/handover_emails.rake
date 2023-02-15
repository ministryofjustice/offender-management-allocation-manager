namespace :handover do
  desc 'send_all_upcoming_handover_window'
  task send_all_upcoming_handover_window: :environment do
    Rails.logger = Logger.new($stdout)
    Handover::HandoverEmailBatchRun.send_all_upcoming_handover_window
  end

  desc 'send_all_handover_date'
  task send_all_handover_date: :environment do
    Rails.logger = Logger.new($stdout)
    Handover::HandoverEmailBatchRun.send_all_handover_date
  end
end
