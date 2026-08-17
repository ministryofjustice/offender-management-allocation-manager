# frozen_string_literal: true

class ProcessPrisonerStatusJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id, trigger_method: :event)
    logger.info("nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_prisoner_status_job,event=started")
    process_status_change(nomis_offender_id)
    logger.info("nomis_offender_id=#{nomis_offender_id},trigger_method=#{trigger_method},job=process_prisoner_status_job,event=finished")
  end

private

  # We allow `UNKNOWN` out of precaution as we've seen brief changes of
  # status from `SENTENCED` to `UNKNOWN` and back to `SENTENCED` and we
  # don't want to deallocate these offenders upon getting the event.
  def allowed_legal_statuses
    HmppsApi::PrisonApi::OffenderApi::ALLOWED_LEGAL_STATUSES + %w[UNKNOWN]
  end

  def process_status_change(nomis_offender_id)
    offender = HmppsApi::PrisonApi::OffenderApi.get_offender(
      nomis_offender_id,
      ignore_legal_status: true,
      fetch_complexities: false,
      fetch_categories: false,
      fetch_movements: false,
      cache: false,
    )

    if offender.nil? || offender.legal_status.blank?
      logger.error(
        "nomis_offender_id=#{nomis_offender_id},job=process_prisoner_status_job,event=missing_offender_record|" \
          'Failed to retrieve NOMIS offender record'
      )
      return
    end

    if allowed_legal_statuses.exclude?(offender.legal_status)
      maybe_inactivate_complexity(offender)

      allocation = AllocationHistory.active.find_by(nomis_offender_id:)
      return if allocation.nil?

      logger.info(
        "nomis_offender_id=#{nomis_offender_id},job=process_prisoner_status_job,event=legal_status_changed|" \
          "Legal status #{offender.legal_status} is not allowed. Deallocating."
      )

      allocation.deallocate_primary_pom(
        event_trigger: AllocationHistory::LEGAL_STATUS_CHANGED
      )
      allocation.deallocate_secondary_pom(
        event_trigger: AllocationHistory::LEGAL_STATUS_CHANGED
      )
    end
  end

  def maybe_inactivate_complexity(offender)
    return if !offender.in_womens_prison? || offender.sentenced? || offender.immigration_case?

    logger.info(
      "nomis_offender_id=#{offender.offender_no},job=process_prisoner_status_job,event=legal_status_changed|" \
        "Legal status #{offender.legal_status} is not allowed. Women prison #{offender.prison_id}. Inactivating CNL."
    )

    HmppsApi::ComplexityApi.inactivate(offender.offender_no)
  end
end
