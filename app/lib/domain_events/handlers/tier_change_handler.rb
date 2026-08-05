module DomainEvents
  module Handlers
    class TierChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "event_version=#{event.version},crn=#{event.crn_number}"

        result = TierUpdateService.call(
          crn: event.crn_number, audit_tags: ['handler']
        )

        case result.status
        when :updated
          logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                        "version=#{result.version},crn=#{event.crn_number},old_tier=#{result.old_tier},new_tier=#{result.new_tier}"
        when :update_failed
          logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
                         "version=#{result.version},crn=#{event.crn_number},old_tier=#{result.old_tier},new_tier=#{result.new_tier}|#{result.errors}"
        when :tier_api_failed
          logger.warn "event=domain_event_handle_tier_api_failed,domain_event_type=#{event.event_type}," \
                        "version=#{result.version},crn=#{event.crn_number}"
        end
      end
    end
  end
end
