module DomainEvents
  module Handlers
    class ProbationChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        case event.event_type
        when /probation-case\.registration\..+/
          handle_registration_change(event, logger)
        when 'OFFENDER_MANAGER_CHANGED', 'OFFENDER_OFFICER_CHANGED', 'OFFENDER_DETAILS_CHANGED'
          call_delius_data_job(event, logger)
        end
      end

    private

      def handle_registration_change(event, logger)
        registration_types = %w[MAPP DASO INVI]

        if registration_types.include?(event.additional_information['registerTypeCode'])
          call_delius_data_job(event, logger)
        else
          logger.info "event=domain_event_handle_noop,domain_event_type=#{event.event_type},crn=#{event.crn_number}" \
                      '|Registration type is not of interest. No action required'
        end
      end

      def call_delius_data_job(event, logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        ProcessDeliusDataJob.perform_now(event.crn_number, identifier_type: :crn, trigger_method: :event, event_type: event.event_type)
        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
      end
    end
  end
end
