# frozen_string_literal: true

class EarlyAllocationEventService
  class << self
    def send_early_allocation(early_allocation_status)
      sns_topic.publish(
        message: {
          offenderNo: early_allocation_status.nomis_offender_id,
          eligibilityStatus: early_allocation_status.eligible,
        }.to_json,
        message_attributes: {
          eventType: {
            string_value: 'community-early-allocation-eligibility.status.changed',
            data_type: 'String',
          },
          version: {
            string_value: 1.to_s,
            data_type: 'Number',
          },
          occurredAt: {
            string_value: early_allocation_status.updated_at.to_s,
            data_type: 'String',
          },
          detailURL: {
            string_value: Rails.application.routes.url_helpers.api_offender_url(early_allocation_status.nomis_offender_id),
            data_type: 'String',
          },
        },
      )
    end

  private

    def sns_topic
      DomainEvents::Event.sns_topic
    end
  end
end
