sentry_dsn = Rails.configuration.sentry_dsn
if sentry_dsn
  Raven.configure do |config|
    config.dsn = sentry_dsn
    config.excluded_exceptions << 'JWT::ExpiredSignature'
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

    # If we're in Heroku, set the environment name to be the current app name
    # This allows us to tell which PR/Review App an error came from
    config.current_environment = ENV['HEROKU_APP_NAME'] if ENV['HEROKU_APP_NAME'].present?
  end
else
  Rails.logger.warn '[WARN] Sentry is not configured (SENTRY_DSN)'
end
