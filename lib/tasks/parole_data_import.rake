# frozen_string_literal: true

namespace :parole do
  desc 'fetch updates to active parole reviews'
  task import: :environment do |_task|
    ParoleDataImportJob.perform_later(Time.zone.today - 1)
  end
end
