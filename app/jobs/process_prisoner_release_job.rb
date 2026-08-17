# frozen_string_literal: true

class ProcessPrisonerReleaseJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id, trigger_method: :event)
    logger.info("nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_prisoner_release_job,event=started")
    process_release(nomis_offender_id)
    logger.info("nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_prisoner_release_job,event=finished")
  end

private

  def process_release(nomis_offender_id)
    MovementService.process_offender_last_movement(nomis_offender_id)
  end
end
