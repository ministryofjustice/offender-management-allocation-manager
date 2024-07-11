class ApplicationMailer < GovukNotifyRails::Mailer
  before_action :store_default_tags
  after_deliver :save_audit_event

  class << self
    attr_reader :mailer_tag

    def set_mailer_tag(tag)
      @mailer_tag = tag
    end
  end

protected

  def store_default_tags
    return if govuk_notify_reference

    mailer_tag = self.class.mailer_tag || self.class.name.underscore.delete_suffix('_mailer')
    set_reference ['email', mailer_tag, action_name].join('.')
  end

  def save_audit_event
    unless message.respond_to?(:govuk_notify_personalisation)
      Rails.logger.error "event=email_not_auditable_error,reason=no_govuk_notify_support|#{message.inspect}"
      return
    end

    params = message.govuk_notify_personalisation
    tags = message.govuk_notify_reference.present? ? message.govuk_notify_reference.split('.') : []
    Rails.logger.error "event=audit_event_created,nomis_offender_id=#{params[:nomis_offender_id]}|#{message.inspect}"
    AuditEvent.publish(
      nomis_offender_id: params[:nomis_offender_id],
      tags: tags,
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
