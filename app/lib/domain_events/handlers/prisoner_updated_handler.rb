class DomainEvents::Handlers::PrisonerUpdatedHandler
  def handle(event)
    nomis_offender_id = event.additional_information.fetch('nomsNumber')

    Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"

    changes = event.additional_information.fetch('categoriesChanged')
    if changes.include?('STATUS')
      # The status of the prisoner has changed, so one of: status, inOutStatus, csra,
      # category, legalStatus, imprisonmentStatus, imprisonmentStatusDescription, recall
      ProcessPrisonerStatusJob.perform_later(nomis_offender_id)
    end

    Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"
  end
end
