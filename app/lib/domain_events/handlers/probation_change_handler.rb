module DomainEvents
  module Handlers
    class ProbationChangeHandler
      def handle(event)
        return unless ENABLE_EVENT_BASED_PROBATION_CHANGE

        case event.event_type
        when /probation-case\.registration\..+/
          handle_registration_added(event)
        when 'OFFENDER_MANAGER_CHANGED'
          call_delius_data_job(event)
        end
      end

    private

      def handle_registration_added(event)
        registration_types = %w[MAPP DASO INVI]
        call_delius_data_job(event) if registration_types.include?(event.additional_information['registerTypeCode'])
      end

      def call_delius_data_job(event)
        Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        ProcessDeliusDataJob.perform_now(event.crn_number, identifier_type: :crn)
        Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
      end
    end
  end
end
