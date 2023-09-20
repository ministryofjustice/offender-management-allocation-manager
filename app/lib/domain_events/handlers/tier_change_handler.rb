module DomainEvents
  module Handlers
    class TierChangeHandler
      def handle(event)
        return unless ENABLE_EVENT_BASED_PROBATION_CHANGE

        Shoryuken::Logging.logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        case_info = CaseInformation.find_by_crn(event.crn_number)

        if case_info.nil?
          Shoryuken::Logging.logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
            "crn=#{event.crn_number}|Case information not found for this CRN"

          return
        end

        tier_info = HmppsApi::TieringApi.get_calculation(event.crn_number, event.additional_information['calculationId'])
        old_tier = case_info.tier
        case_info.tier = tier_info[:tier][0]

        if case_info.save
          AuditEvent.publish(
            nomis_offender_id: case_info.nomis_offender_id,
            tags: %w[handler case_information tier changed],
            system_event: true,
            data: {
              'before' => old_tier,
              'after' => case_info.tier
            }
          )

          Shoryuken::Logging.logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        else
          Shoryuken::Logging.logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
            "crn=#{event.crn_number},new_tier=#{case_info.tier}"
        end
      end
    end
  end
end
