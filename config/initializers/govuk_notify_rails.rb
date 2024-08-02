ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery,
                                       api_key: ENV['GOVUK_NOTIFY_API_KEY']

Rails.application.config.to_prepare do
  ApplicationMailer.register_interceptor(NotifyMailInterceptor)
  ApplicationMailer.register_observer(AuditEventsMailObserver)
  ApplicationMailer.register_observer(EmailHistoryMailObserver)
end
