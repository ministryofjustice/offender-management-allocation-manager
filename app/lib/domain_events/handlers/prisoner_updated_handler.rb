class DomainEvents::Handlers::PrisonerUpdatedHandler
  DEBOUNCE_KEY_PREFIX = 'domain_events:prisoner_updated_handover'.freeze
  DEBOUNCE_WINDOW = 1.hour

  def handle(event)
    nomis_offender_id = event.additional_information.fetch('nomsNumber')

    Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"

    changes = event.additional_information.fetch('categoriesChanged')

    if changes.include?('STATUS') && AllocationHistory.active.exists?(nomis_offender_id:)
      # The status of the prisoner has changed, so one of: status, inOutStatus, csra,
      # category, legalStatus, imprisonmentStatus, imprisonmentStatusDescription, recall
      ProcessPrisonerStatusJob.perform_later(nomis_offender_id)
    end

    if changes.include?('SENTENCE')
      debounce_handover_recalculation(nomis_offender_id)
    end

    Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},nomis_offender_id=#{nomis_offender_id}"
  end

private

  def debounce_handover_recalculation(nomis_offender_id)
    # Quick check to avoid creating cache entries and debounced jobs for offenders
    # we don't manage as the event fires for every prisoner change across NOMIS
    return unless CalculatedHandoverDate.exists?(nomis_offender_id:)

    debounce_key = "#{DEBOUNCE_KEY_PREFIX}:#{nomis_offender_id}"
    debounce_token = SecureRandom.uuid
    Rails.cache.write(debounce_key, debounce_token, expires_in: 2.hours)

    DebouncedRecalculateHandoverDateJob.set(wait: DEBOUNCE_WINDOW).perform_later(
      nomis_offender_id,
      debounce_key:,
      debounce_token:,
    )
  end
end
