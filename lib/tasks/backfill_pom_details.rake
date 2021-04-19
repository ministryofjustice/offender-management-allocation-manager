# frozen_string_literal: true

require 'rake'

namespace :backfill do
  desc 'Back-fill pom_details with prison_code'
  task pom_details: :environment do
    Rails.logger = Logger.new(STDOUT)

    Prison.all.each do |prison|
      PrisonOffenderManagerService.get_poms_for(prison.code).map(&:staff_id).each { |staff_id|
        pom = PomDetail.find_by! nomis_staff_id: staff_id
        pom.update! prison_code: prison.code
      }
    end
  end
end
