class EarlyAllocationEventJob < ApplicationJob
  queue_as :default

  def perform(offender_id)
    offender = OffenderService.get_offender(offender_id)
    EarlyAllocationService.process_eligibility_change(offender) unless offender.nil?
  end
end
