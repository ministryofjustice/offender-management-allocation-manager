module DomainEvents
  module Handlers
    class ProbationChangeHandler
      def handle(event)
        return unless ENABLE_EVENT_BASED_PROBATION_CHANGE

        case event.event_type
        when /probation-case\.registration\..+/
          handle_registration_added(event)
        end
      end

    private

      def handle_registration_added(event)
        registration_event_types = %w[MAPP DASO INVI]

        return unless registration_event_types.include?(event.additional_information['registerTypeCode'])

        Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        ProcessDeliusDataJob.perform_now(event.crn_number, identifier_type: :crn)
        Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
      end
    end
  end
end
