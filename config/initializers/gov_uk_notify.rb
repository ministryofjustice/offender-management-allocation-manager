ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery,
  api_key: Rails.configuration.notify_api_key
