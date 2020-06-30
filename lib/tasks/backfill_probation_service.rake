# frozen_string_literal: true

require 'rake'

namespace :backfill do
  desc 'Back-fill case_information#probation_service from welsh_offender'
  task probation_service: :environment do
    CaseInformation.where(probation_service: nil).find_each do |ci|
      ci.update!(probation_service: ci.welsh_offender ? 'Wales' : 'England')
    end
  end
end
