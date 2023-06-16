class ApplicationMailer < GovukNotifyRails::Mailer
  before_action :store_default_tags

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
