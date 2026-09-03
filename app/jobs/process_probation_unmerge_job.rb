# frozen_string_literal: true

class ProcessProbationUnmergeJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordInvalid

  def perform(reactivated_crn, unmerged_crn, event_type:)
    logger.info(
      "reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}," \
      "event_type=#{event_type},job=process_probation_unmerge_job,event=started"
    )

    ProbationUnmergeService.new(
      old_crn: reactivated_crn, new_crn: unmerged_crn, logger:
    ).process

    logger.info(
      "reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}," \
      "event_type=#{event_type},job=process_probation_unmerge_job,event=finished"
    )
  end
end
