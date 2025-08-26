# frozen_string_literal: true

require 'rake'

namespace :deallocate_unsentenced_offenders do
  desc 'De-allocate cases for offenders that have a non-allowed legal status, like unsentenced, remand, dead, etc.'
  task process: :environment do
    # Older than 2 months ago because after that date we started handling
    # deallocations via events, upon receiving legal status updates.
    AllocationHistory.active.where('updated_at <= ?', 2.months.ago).pluck(:nomis_offender_id).each do |nomis_offender_id|
      ProcessPrisonerStatusJob.perform_later(nomis_offender_id)
    end
  end
end
