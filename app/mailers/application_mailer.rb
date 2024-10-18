class ApplicationMailer < GovukNotifyRails::Mailer
  # Disable logging of arguments when sending emails
  # as they usually contain PII details
  delivery_job.log_arguments = false

  before_action :store_default_tags

  # Report the exception but do not re-raise it, as these errors
  # are not recoverable so it is not useful to retry failed jobs
  # :nocov:
  rescue_from 'Notifications::Client::BadRequestError' do |ex|
    Rails.logger.warn("[#{self.class}] #{ex} - #{message.to}")
    Sentry.capture_exception(
      ex, contexts: { recipient: { emails: message.to.join(',') } }
    )
  end
  # :nocov:

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
end
