namespace :handover do
  desc 'Send all handover reminder emails for today'
  task send_all_handover_reminders: :environment do
    Rails.logger = Logger.new($stdout) if Rails.env.production?
    Handover::HandoverEmailBatchRun.send_all
  end
end
