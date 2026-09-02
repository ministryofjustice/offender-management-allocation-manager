# frozen_string_literal: true

class ProcessPrisonerMergeJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordInvalid

  def perform(old_offender_id, new_offender_id, event_type:)
    logger.info(
      "old_offender_id=#{old_offender_id},new_offender_id=#{new_offender_id}," \
      "event_type=#{event_type},job=process_prisoner_merge_job,event=started"
    )

    PrisonerMergeService.new(
      old_offender_id:, new_offender_id:, logger:
    ).process

    logger.info(
      "old_offender_id=#{old_offender_id},new_offender_id=#{new_offender_id}," \
      "event_type=#{event_type},job=process_prisoner_merge_job,event=finished"
    )
  end
end
