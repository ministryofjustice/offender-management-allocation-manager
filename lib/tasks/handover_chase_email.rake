# frozen_string_literal: true

require 'rake'

namespace :handover_chase_emails do
  desc 'Send follow-up emails LDUs two weeks before handover if COM still not assigned'
  task process: :environment do
    HandoverFollowUpJob.perform_later(Time.zone.today)
  end
end
