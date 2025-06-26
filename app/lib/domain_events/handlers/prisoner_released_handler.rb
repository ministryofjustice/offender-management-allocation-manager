class DomainEvents::Handlers::PrisonerReleasedHandler
  def handle(event, logger: Shoryuken::Logging.logger)
    nomis_offender_id = event.additional_information.fetch('nomsNumber')
    reason = event.additional_information.fetch('reason')

    logger.info("event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                "nomis_offender_id=#{nomis_offender_id},reason=#{reason}")

    # Possible release reasons:
    #
    # TEMPORARY_ABSENCE_RELEASE - released on temporary absence
    # RELEASED_TO_HOSPITAL - released to a secure hospital
    # RELEASED - released from prison
    # SENT_TO_COURT - sent to court
    # TRANSFERRED - transfer to another prison
    #
    # We only care about some of these for real-time, the rest are
    # handled through the movements nightly job.
    #
    if %w[RELEASED TRANSFERRED].include?(reason)
      ProcessPrisonerReleaseJob.perform_later(nomis_offender_id)
    end

    logger.info("event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                "nomis_offender_id=#{nomis_offender_id},reason=#{reason}")
  end
end
