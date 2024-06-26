# frozen_string_literal: true

class EarlyAllocationService
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

    def process_eligibility_change(offender)
      ea_status = CalculatedEarlyAllocationStatus.find_or_initialize_by(nomis_offender_id: offender.nomis_offender_id)
      ea_status.eligible = offender.early_allocation?

      if ea_status.changed?
        changes = ea_status.changes.fetch('eligible')
        ea_status.save!
        AuditEvent.transaction do
          send_early_allocation(ea_status)
          AuditEvent.publish(
            nomis_offender_id: offender.nomis_offender_id,
            tags: %w[early_allocation eligibility_updated],
            system_event: true,
            data: {
              'before' => { 'eligible' => changes[0] },
              'after' => { 'eligible' => changes[1] },
            }
          )
        end
        RecalculateHandoverDateJob.perform_now(offender.nomis_offender_id)
      end
    end

  private

    def sns_topic
      DomainEvents::Event.sns_topic
    end
  end
end
