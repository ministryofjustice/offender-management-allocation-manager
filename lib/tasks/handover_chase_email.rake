# frozen_string_literal: true

require 'rake'

namespace :handover_chase_emails do
  desc 'Send follow-up emails LDUs two weeks before handover if COM still not assigned'
  task process: :environment do
    LocalDeliveryUnit.enabled.each do |ldu|
      HandoverFollowUpJob.perform_later(ldu)
    end
  end
end
