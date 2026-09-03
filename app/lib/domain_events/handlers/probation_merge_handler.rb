module DomainEvents
  module Handlers
    class ProbationMergeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        case event.event_type
        when 'probation-case.merge.completed'
          handle_probation_case_merge(event, logger)
        when 'probation-case.unmerge.completed'
          handle_probation_case_unmerge(event, logger)
        end
      end

    private

      def handle_probation_case_merge(event, logger)
        source_crn = event.additional_information.fetch('sourceCRN')
        target_crn = event.additional_information.fetch('targetCRN')

        context = merge_log_context(event:, old_crn: source_crn, new_crn: target_crn)
        log_event(logger, event_name: 'domain_event_handle_start', context:)

        if ProbationMergeService.locally_tracked?(source_crn)
          ProcessProbationMergeJob.perform_later(
            source_crn, target_crn, event_type: event.event_type
          )
        else
          log_event(
            logger, event_name: 'domain_event_handle_noop', context:, message: 'Old CRN untracked locally'
          )
        end

        log_event(logger, event_name: 'domain_event_handle_success', context:)
      end

      def handle_probation_case_unmerge(event, logger)
        reactivated_crn = event.additional_information.fetch('reactivatedCRN')
        unmerged_crn = event.additional_information.fetch('unmergedCRN')

        context = merge_log_context(event:, old_crn: reactivated_crn, new_crn: unmerged_crn)
        log_event(logger, event_name: 'domain_event_handle_start', context:)

        if ProbationUnmergeService.locally_tracked?(old_crn: reactivated_crn, new_crn: unmerged_crn)
          ProcessProbationUnmergeJob.perform_later(
            reactivated_crn, unmerged_crn, event_type: event.event_type
          )
        else
          log_event(
            logger, event_name: 'domain_event_handle_noop', context:, message: 'Merge mapping not tracked locally'
          )
        end

        log_event(logger, event_name: 'domain_event_handle_success', context:)
      end

      def merge_log_context(event:, old_crn:, new_crn:)
        "domain_event_type=#{event.event_type},old_crn=#{old_crn},new_crn=#{new_crn}"
      end

      def log_event(logger, event_name:, context:, message: nil)
        payload = "event=#{event_name},#{context}"
        payload += "|#{message}" if message
        logger.info(payload)
      end
    end
  end
end
