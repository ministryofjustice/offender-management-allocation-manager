# frozen_string_literal: true

namespace :cronjob do
  desc 'fetch updates to active parole records'
  task import_parole_record_updates: :environment do |_task|
    ParoleDataImportJob.perform_later(Time.zone.today)
  end
end
