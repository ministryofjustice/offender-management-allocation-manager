class MailPublishAuditEventObserver
  def self.delivered_email(message)
    unless message.respond_to?(:govuk_notify_personalisation)
      Rails.logger.error "event=email_not_auditable_error,reason=no_govuk_notify_support|#{message.inspect}"
      return
    end

    params = message.govuk_notify_personalisation
    tags = message.govuk_notify_reference.present? ? message.govuk_notify_reference.split('.') : []
    Rails.logger.error "event=audit_event_created,nomis_offender_id=#{params[:nomis_offender_id]}|#{message.inspect}"
    AuditEvent.create!(
      nomis_offender_id: params[:nomis_offender_id],
      tags: tags,
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
