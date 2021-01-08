sentry_dsn = Rails.configuration.sentry_dsn
Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger]
  if sentry_dsn
    config.dsn = sentry_dsn
  else
    Rails.logger.warn '[WARN] Sentry is not configured (SENTRY_DSN)' unless sentry_dsn
  end
  config.excluded_exceptions << 'JWT::ExpiredSignature'
  if ENV['HEROKU_BRANCH']
    config.environment = ENV.fetch('HEROKU_BRANCH')
  end

  # Filter out sensitive fields from sentry logs
  sanitize_fields = Rails.application.config.filter_parameters
  config.before_send = lambda do |event|
    sanitize_fields.each do |field|
      event.remove(field)
    end
    event
  end
end
