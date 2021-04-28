# frozen_string_literal: true

require 'rake'
namespace :import do
  desc 'updates production when new prisons are added or modified'
  task prison: :environment do
    PrisonService::PRISONS.values.each do |prison|
      # If prison data is already present it runs update instead to prevent a crash
      db_prison = Prison.find_by(code: prison.code)
      if db_prison.present?
        db_prison.update!(name: prison.name, prison_type: PrisonService.prison_type(prison))
      else
        Prison.create!(code: prison.code, name: prison.name, prison_type: PrisonService.prison_type(prison))
      end
    end
  end
end
