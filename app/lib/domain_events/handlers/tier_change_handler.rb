module DomainEvents
  module Handlers
    class TierChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "event_version=#{event.version},crn=#{event.crn_number}"

        if CaseInformation.exists?(crn: event.crn_number)
          ProcessTierChangeJob.perform_later(
            event.crn_number,
            event_type: event.event_type,
          )
        end

        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                      "event_version=#{event.version},crn=#{event.crn_number}"
      end
    end
  end
end
