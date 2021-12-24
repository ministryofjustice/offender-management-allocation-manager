# frozen_string_literal: true

class PushHandoverDatesToDeliusJob < ApplicationJob
  queue_as :default
  include MutexHelper

  def perform record
    begin
      HmppsApi::CommunityApi.set_handover_dates(
        offender_no: record.nomis_offender_id,
        handover_start_date: record.start_date,
        responsibility_handover_date: record.handover_date
      )
      # if previous push to Delius failed, remove the Cache flag now its been pushed
      if lock_exists(ProcessDeliusDataJob::JOB_NAME, record.nomis_offender_id)
        remove_lock(ProcessDeliusDataJob::JOB_NAME, record.nomis_offender_id)
      end
    rescue Faraday::BadRequestError
      # BadRequest is returned from Delius when there is more than one active case
      # and the system does not know which record to update. This can only be resolved when Delius
      # is updated to remove duplicate records. We have to retry until the push is successful
      create_lock(ProcessDeliusDataJob::JOB_NAME, record.nomis_offender_id)
    end
  end
end
