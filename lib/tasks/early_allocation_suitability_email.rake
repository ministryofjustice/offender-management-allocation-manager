# frozen_string_literal: true

require 'rake'

namespace :early_allocation_suitability_email do
  desc 'Send emails to allocated POMs whose offenders have Early Allocation assessment forms due to be reviewed now'
  task process: :environment do
    SuitableForEarlyAllocationEmailJob.perform_later
  end
end
