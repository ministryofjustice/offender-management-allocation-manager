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
    def personalisation = govuk_notify_personalisation
    def tags = String(govuk_notify_reference).split('.')
    def template = govuk_notify_template

    def nomis_offender_id
      [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| personalisation[key] }
        .find(&:itself)
    end
  end
end
