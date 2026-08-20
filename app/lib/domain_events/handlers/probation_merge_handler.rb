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

        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "source_crn=#{source_crn},target_crn=#{target_crn}"

        # TODO: to be implemented
        logger.info "[MERGE] source case exists? #{CaseInformation.exists?(crn: source_crn)} - " \
                      "target case exists? #{CaseInformation.exists?(crn: target_crn)}" \

        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                      "source_crn=#{source_crn},target_crn=#{target_crn}"
      end

      def handle_probation_case_unmerge(event, logger)
        reactivated_crn = event.additional_information.fetch('reactivatedCRN')
        unmerged_crn = event.additional_information.fetch('unmergedCRN')

        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}"

        # TODO: to be implemented
        logger.info "[UNMERGE] reactivated case exists? #{CaseInformation.exists?(crn: reactivated_crn)} - " \
                      "unmerged case exists? #{CaseInformation.exists?(crn: unmerged_crn)}"

        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                      "reactivated_crn=#{reactivated_crn},unmerged_crn=#{unmerged_crn}"
      end
    end
  end
end
