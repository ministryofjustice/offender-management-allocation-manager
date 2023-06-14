class MailPublishAuditEventObserver
  def self.delivered_email(message)
    return unless message.respond_to?(:govuk_notify_personalisation)

    params = message.govuk_notify_personalisation
    AuditEvent.create!(
      nomis_offender_id: params[:nomis_offender_id],
      tags: message.govuk_notify_reference || [],
      published_at: Time.zone.now.utc,
      system_event: true,
      data: {
        'govuk_notify_message' => {
          'to' => message.to,
          'template' => message.govuk_notify_template,
          'personalisation' => params,
        }
      }
    )
  end
end
