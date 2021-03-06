# frozen_string_literal: true

namespace :cronjob do
  desc 'send monthly handover emails'
  task handover_email: :environment do |_task|
    # Send to 'old' LDUs
    # These will be removed in February 2021 after the PDU/LDU go live
    LocalDivisionalUnit.with_email_address.each do |ldu|
      AutomaticHandoverEmailJob.perform_later(ldu)
    end

    # Send to 'new' (2021) LDUs
    LocalDeliveryUnit.enabled.each do |ldu|
      AutomaticHandoverEmailJob.perform_later(ldu)
    end
  end
end
