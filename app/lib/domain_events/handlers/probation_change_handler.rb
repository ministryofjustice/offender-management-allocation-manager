module DomainEvents
  module Handlers
    class ProbationChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        unless ENABLE_EVENT_BASED_PROBATION_CHANGE
          logger.info "event=domain_event_handle_skip,domain_event_type=#{event.event_type},crn=#{event.crn_number}" \
                      '|Skipping handling because feature flag is not set'
          return
        end

        case event.event_type
        when /probation-case\.registration\..+/
          handle_registration_added(event, logger)
        when 'OFFENDER_MANAGER_CHANGED'
          call_delius_data_job(event, logger)
        end
      end

    private

      def handle_registration_added(event, logger)
        registration_types = %w[MAPP DASO INVI]
        call_delius_data_job(event, logger) if registration_types.include?(event.additional_information['registerTypeCode'])
      end

      def call_delius_data_job(event, logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        ProcessDeliusDataJob.perform_now(event.crn_number, identifier_type: :crn)
        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
      end
    end
  end
end
