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
    last_movement = HmppsApi::PrisonApi::MovementApi.movements_for(
      nomis_offender_id, movement_types: []
    ).last_movement

    if last_movement
      MovementService.process_movement(last_movement)
    else
      logger.error(
        "nomis_offender_id=#{nomis_offender_id},job=process_prisoner_release_job,event=missing_movement_record|" \
        'Failed to retrieve offender movements'
      )
    end
  end
end
