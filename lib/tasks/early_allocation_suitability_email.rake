# frozen_string_literal: true

require 'rake'

namespace :early_allocation_suitability_email do
  desc 'Send emails to allocated POMs whose offenders have Early Allocation assessment forms due to be reviewed now'
  task process: :environment do
    offenders = EarlyAllocation.active_pre_referral_window.pluck(:nomis_offender_id).uniq

    offenders.each do |offender|
      SuitableForEarlyAllocationEmailJob.perform_later(offender)
    end
  end
end
