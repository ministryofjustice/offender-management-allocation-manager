# frozen_string_literal: true

namespace :community_api do
  desc 'Import data from Community API'
  task import: :environment do |_task|
    Rails.logger = Logger.new(STDOUT)

    Prison.active.each do |prison|
      prison.offenders.each do |offender|
        ProcessDeliusDataJob.perform_later offender.offender_no
      end
    end
  end
end
