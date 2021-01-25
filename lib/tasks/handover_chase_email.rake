# frozen_string_literal: true

require 'rake'

namespace :handover_chase_emails do
  desc 'Send follow-up emails LDUs two weeks before handover if COM still not assigned'
  task process: :environment do
    # Send to 'old' LDUs
    # These will be removed in February 2021 after the PDU/LDU go live
    LocalDivisionalUnit.with_email_address.each do |ldu|
      HandoverFollowUpJob.perform_later(ldu)
    end

    # Send to 'new' (2021) LDUs
    LocalDeliveryUnit.enabled.each do |ldu|
      HandoverFollowUpJob.perform_later(ldu)
    end
  end
end
