module DomainEvents
  module Handlers
    class PrisonerMergeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        new_offender_id = event.additional_information.fetch('nomsNumber')
        old_offender_id = event.additional_information.fetch('removedNomsNumber')

        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "new_offender_id=#{new_offender_id},old_offender_id=#{old_offender_id}"

        # TODO: to be implemented
        logger.info "[MERGE] new case exists? #{CaseInformation.exists?(nomis_offender_id: new_offender_id)} - " \
                      "old case exists? #{CaseInformation.exists?(nomis_offender_id: old_offender_id)}"

        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                      "new_offender_id=#{new_offender_id},old_offender_id=#{old_offender_id}"
      end
    end
  end
end
