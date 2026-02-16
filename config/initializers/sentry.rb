sentry_dsn = Rails.configuration.sentry_dsn

if sentry_dsn
  require 'active_support/parameter_filter'
  param_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

  Sentry.init do |config|
    config.dsn = sentry_dsn
    config.release = ENV['BUILD_NUMBER']
    config.excluded_exceptions << 'JWT::ExpiredSignature'
    config.enable_metrics = false

    config.before_send = lambda do |event, hint|
      return nil if hint[:exception]&.full_message&.match?(/ApplicationInsights::TelemetryClient/)
      return nil unless SentryCircuitBreakerService.check_within_quota

      # Sanitize extra data
      if event.extra
        event.extra = param_filter.filter(event.extra)
      end

      # Sanitize user data
      if event.user
        event.user = param_filter.filter(event.user)
      end

      # Sanitize context data
      if event.contexts
        event.contexts = param_filter.filter(event.contexts)
      end

      # Return the sanitized event object
      event
    end
  end
else
  Rails.logger.warn '[WARN] Sentry is not configured (SENTRY_DSN)'
end
