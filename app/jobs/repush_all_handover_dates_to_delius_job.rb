# frozen_string_literal: true

# Sometimes the PushToDeliusDataJob during the ReallocateHandoverDateJob fails.
# This is a job to push the handover dates of all offenders, to attempt to bring Delius fully up-to-date.
# This job is not the solution to the problem, and should only be used as a temporary stop-gap until a solution can be found.
class RepushAllHandoverDatesToDeliusJob < ApplicationJob
  queue_as :default

  def perform
    Prison.all.each do |prison|
      prison.offenders.each do |offender|
        handover_date = Offender.find(offender.offender_no).calculated_handover_date
        begin
          PushHandoverDatesToDeliusJob.perform_now(handover_date)
        rescue StandardError => e
          Rails.logger.error e.message
        end
      end
    end
  end
end
