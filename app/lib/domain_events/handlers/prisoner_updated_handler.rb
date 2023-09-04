class DomainEvents::Handlers::PrisonerUpdatedHandler
  def handle(event)
    return unless ENABLE_EVENT_BASED_HANDOVER_CALCULATION

    nomis_offender_id = event.additional_information.fetch('nomsNumber')
    Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"
    categories = event.additional_information.fetch('categoriesChanged')
    RecalculateHandoverDateJob.perform_now(nomis_offender_id) if categories.include?('SENTENCE')
    Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"
  end
end
