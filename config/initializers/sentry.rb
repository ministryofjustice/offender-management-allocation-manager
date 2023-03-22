sentry_dsn = Rails.configuration.sentry_dsn

if sentry_dsn
  param_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

  Sentry.init do |config|
    config.dsn = sentry_dsn
    config.excluded_exceptions << 'JWT::ExpiredSignature'

    config.before_send = lambda do |event, _hint|
      SentryCircuitBreakerService.check_within_quota ? param_filter.filter(event.to_hash) : nil
    end
  end
else
  Rails.logger.warn '[WARN] Sentry is not configured (SENTRY_DSN)'
end
