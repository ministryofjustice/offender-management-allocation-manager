# frozen_string_literal: true

require 'rake'

namespace :deactivate_released_cnls do
  desc 'Deactivate complexity of need levels for released offenders'
  task process: :environment do
    women_prisons = Prison.where(code: PrisonService::WOMENS_PRISON_CODES)
    women_prisons_count = women_prisons.size

    women_prisons.each_with_index do |prison, i|
      puts "Enqueuing prison #{i + 1}/#{women_prisons_count}: #{prison.code} - #{prison.name}"
      DeactivateReleasedCnlsJob.perform_later(prison)
    end
  end
end
