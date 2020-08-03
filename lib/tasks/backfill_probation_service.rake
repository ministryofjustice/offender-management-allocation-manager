# frozen_string_literal: true

require 'rake'

namespace :backfill do
  desc 'Back-fill case_information#probation_service from welsh_offender'
  task probation_service: :environment do
    CaseInformation.where(probation_service: nil, welsh_offender: 'Yes').update_all(probation_service: 'Wales')
    CaseInformation.where(probation_service: nil, welsh_offender: 'No').update_all(probation_service: 'England')
  end
end
