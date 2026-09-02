# frozen_string_literal: true

module DomainEvents
  module Handlers
    class PrisonerMergeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        new_offender_id = event.additional_information.fetch('nomsNumber')
        old_offender_id = event.additional_information.fetch('removedNomsNumber')

        context = merge_log_context(event:, old_offender_id:, new_offender_id:)
        log_event(logger, event_name: 'domain_event_handle_start', context:)

        if PrisonerMergeService.locally_tracked?(old_offender_id)
          ProcessPrisonerMergeJob.perform_later(
            old_offender_id, new_offender_id, event_type: event.event_type
          )
        else
          log_event(
            logger, event_name: 'domain_event_handle_noop', context:, message: 'Old offender untracked locally'
          )
        end

        log_event(logger, event_name: 'domain_event_handle_success', context:)
      end

    private

      def merge_log_context(event:, old_offender_id:, new_offender_id:)
        "domain_event_type=#{event.event_type},old_offender_id=#{old_offender_id},new_offender_id=#{new_offender_id}"
      end

      def log_event(logger, event_name:, context:, message: nil)
        payload = "event=#{event_name},#{context}"
        payload += "|#{message}" if message
        logger.info(payload)
      end
    end
  end
end
