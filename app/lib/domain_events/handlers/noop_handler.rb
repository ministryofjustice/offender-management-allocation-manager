module DomainEvents
  module Handlers
    class NoopHandler
      def handle(event)
        Shoryuken::Logging.logger.info "event=domain_event_handle_success|#{ActiveSupport::JSON.encode(event.message)}"
      end
    end
  end
end
