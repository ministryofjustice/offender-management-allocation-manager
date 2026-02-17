module DomainEvents
  module Handlers
    class TierChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
        case_info = CaseInformation.find_by_crn(event.crn_number)

        if case_info.nil?
          logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
            "crn=#{event.crn_number}|Case information not found for this CRN"

          return
        end

        api_tier_info = HmppsApi::TieringApi.get_calculation(event.crn_number, event.additional_information['calculationId'])
        new_tier = api_tier_info[:tier][0]
        old_tier = case_info.tier

        if new_tier == old_tier
          logger.info "event=domain_event_handle_noop,domain_event_type=#{event.event_type},crn=#{event.crn_number}" \
                      '|Tier value has not changed'

          return
        end

        case_info.tier = new_tier

        if case_info.save
          AuditEvent.publish(
            nomis_offender_id: case_info.nomis_offender_id,
            tags: %w[handler case_information tier changed],
            system_event: true,
            data: {
              'before' => old_tier,
              'after' => new_tier
            }
          )

          logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                        "crn=#{event.crn_number},old_tier=#{old_tier},new_tier=#{new_tier}"
        else
          logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
            "crn=#{event.crn_number}|Error saving case information"
        end
      end
    end
  end
end
