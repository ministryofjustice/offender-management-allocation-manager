#
# NOTE: in `staging` we are using a "team and guest list" API key
# that limits who we can send emails to. Some emails on `staging`
# will attempt to send but Notify will reject the API request if
# the recipient is not part of the team or guest list. It's fine.
#
# In `production` there is no limitation as we are using a "live"
# key that sends email to anyone.
#
# Even with `perform_deliveries = false`, the mail lifecycle is
# intact, so any observers will still get called.
#
class NotifyMailInterceptor
  ALLOWED_ENV_NAMES = %w[staging production].freeze

  class << self
    def delivering_email(message)
      return if allow_delivery?

      message.perform_deliveries = false
      Rails.logger.info "NotifyMailInterceptor prevented sending email to: #{message.to}"
    end

  private

    def allow_delivery?
      ALLOWED_ENV_NAMES.include?(ENV['ENV_NAME'])
    end
  end
end
