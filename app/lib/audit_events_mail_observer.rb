class AuditEventsMailObserver
  def self.delivered_email(message)
    audit_details = AuditDetails.new(message)

    AuditEvent.publish(
      nomis_offender_id: audit_details.nomis_offender_id,
      tags: audit_details.tags,
      system_event: true,
      data: {
        govuk_notify_message: {
          to: audit_details.to,
          template: audit_details.template,
          personalisation: audit_details.personalisation
        }
      }
    )
  end

  class AuditDetails < SimpleDelegator
    def template = govuk_notify_template

    def personalisation
      Hash(govuk_notify_personalisation).tap do |hash|
        hash.deep_merge!(link_to_document: { file: 'REDACTED' }) if hash.key?(:link_to_document)
      end
    end

    def tags
      tags = String(govuk_notify_reference).split('.')
      tags << "perform_deliveries_#{perform_deliveries}"
    end

    def nomis_offender_id
      [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| personalisation[key] }
        .find(&:itself)
    end
  end
end
