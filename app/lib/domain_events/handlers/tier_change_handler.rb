module DomainEvents
  module Handlers
    class TierChangeHandler
      def handle(event, logger: Shoryuken::Logging.logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type}," \
                      "version=#{event.version},crn=#{event.crn_number}"

        case_info = CaseInformation.find_by(crn: event.crn_number)
        return if case_info.nil?

        api_tier_info = HmppsApi::TieringApi.get_calculation(
          event.crn_number, event.additional_information['calculationId'], version: event.version
        )
        return if api_tier_info.try(:[], :tier).nil?

        new_tier = api_tier_info[:tier][0]
        old_tier = case_info.tier

        return if new_tier == old_tier

        case_info.tier = new_tier
        case_info.manual_entry = false

        attrs_before = case_info.changed_attributes

        if case_info.save
          AuditEvent.publish(
            nomis_offender_id: case_info.nomis_offender_id,
            tags: %w[handler case_information tier changed],
            system_event: true,
            data: {
              'before' => attrs_before,
              'after' => case_info.slice(attrs_before.keys)
            }
          )

          logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type}," \
                        "version=#{event.version},crn=#{event.crn_number},old_tier=#{old_tier},new_tier=#{new_tier}"
        else
          logger.error "event=domain_event_handle_failure,domain_event_type=#{event.event_type}," \
            "version=#{event.version},crn=#{event.crn_number},old_tier=#{old_tier},new_tier=#{new_tier}|#{case_info.errors.full_messages.join(',')}"
        end
      end
    end
  end
end
