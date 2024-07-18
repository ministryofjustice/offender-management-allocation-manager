class AuditEventsMailObserver
  def self.delivered_email(message)
    tags = String(message.govuk_notify_reference).split('.')
    personalisation = message.govuk_notify_personalisation
    template = message.govuk_notify_template
    to = message.to
    nomis_offender_id = personalisation[:nomis_offender_id] || personalisation[:prisoner_number]

    Rails.logger.error "event=audit_event_created,nomis_offender_id=#{nomis_offender_id}|#{message.inspect}"

    AuditEvent.publish(
      nomis_offender_id:,
      tags:,
      system_event: true,
      data: { govuk_notify_message: { to:, template:, personalisation: } }
    )
  end
end
