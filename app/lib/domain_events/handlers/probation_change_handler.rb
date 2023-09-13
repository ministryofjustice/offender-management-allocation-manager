module DomainEvents
  module Handlers
    class ProbationChangeHandler
      def handle(event)
        return unless ENABLE_EVENT_BASED_PROBATION_CHANGE

        handle_registration_added(event)
      end

    private

      def handle_registration_added(event)
        registration_event_types = %w[MAPP DASO INVI]

        return unless registration_event_types.include?(event.additional_information['registerTypeCode'])

        offender_no = to_offender_no(event.crn_number)
        Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},nomis_offender_id=#{offender_no}"
        ProcessDeliusDataJob.perform_now offender_no
        Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},nomis_offender_id=#{offender_no}"
      end

      def to_offender_no(_crn)
        # Pending EITHER NOMIS offender no. being added to the events OR an endpoint
        # to convert CRN to NOMIS offender no. being added
        'FIXME'
      end
    end
  end
end
