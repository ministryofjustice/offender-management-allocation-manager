# frozen_string_literal: true

class ProcessProbationMergeJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordInvalid

  def perform(old_crn, new_crn, event_type:)
    logger.info(
      "old_crn=#{old_crn},new_crn=#{new_crn}," \
      "event_type=#{event_type},job=process_probation_merge_job,event=started"
    )

    ProbationMergeService.new(
      old_crn:, new_crn:, logger:
    ).process

    logger.info(
      "old_crn=#{old_crn},new_crn=#{new_crn}," \
      "event_type=#{event_type},job=process_probation_merge_job,event=finished"
    )
  end
end
