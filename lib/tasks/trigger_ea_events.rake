# frozen_string_literal: true

require 'rake'

namespace :trigger do
  desc 'Send an event if early allocation changed OOB (due to e.g. time passing)'
  task early_allocation_events: :environment do
    next if ENABLE_EVENT_BASED_HANDOVER_CALCULATION

    Offender.find_each do |offender|
      EarlyAllocationEventJob.perform_later(offender.nomis_offender_id)
    end
  end
end
