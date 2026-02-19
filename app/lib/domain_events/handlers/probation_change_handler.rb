module DomainEvents
  module Handlers
    class ProbationChangeHandler
      DEBOUNCE_KEY_PREFIX = 'domain_events:probation_change'.freeze
      DEBOUNCE_WINDOW = 3.seconds

      HANDLED_REGISTRATION_TYPES = %w[MAPP DASO INVI].freeze

      def handle(event, logger: Shoryuken::Logging.logger)
        case event.event_type
        when /probation-case\.registration\..+/
          handle_registration_change(event, logger)
        when 'OFFENDER_MANAGER_CHANGED', 'OFFENDER_OFFICER_CHANGED', 'OFFENDER_DETAILS_CHANGED'
          call_delius_data_job(event, logger)
        end
      end

    private

      def handle_registration_change(event, logger)
        if HANDLED_REGISTRATION_TYPES.include?(event.additional_information['registerTypeCode'])
          call_delius_data_job(event, logger)
        else
          logger.info "event=domain_event_handle_noop,domain_event_type=#{event.event_type},crn=#{event.crn_number}" \
                      '|Registration type is not of interest. No action required'
        end
      end

      def call_delius_data_job(event, logger)
        logger.info "event=domain_event_handle_start,domain_event_type=#{event.event_type},crn=#{event.crn_number}"

        debounce_key = "#{DEBOUNCE_KEY_PREFIX}:#{event.crn_number}"
        debounce_token = SecureRandom.uuid
        Rails.cache.write(debounce_key, debounce_token, expires_in: 10.minutes)

        # If we receive multiple events for the same CRN in quick succession, we only
        # really care about the final probation record data, thus this simple debouncing
        DebouncedProcessDeliusDataJob.set(wait: DEBOUNCE_WINDOW).perform_later(
          event.crn_number,
          event_type: event.event_type,
          debounce_key:,
          debounce_token:,
        )

        logger.info "event=domain_event_handle_success,domain_event_type=#{event.event_type},crn=#{event.crn_number}"
      end
    end
  end
end
