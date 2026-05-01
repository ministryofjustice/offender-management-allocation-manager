# This subscriber will log exceptions to stdout, when using
# new Rails error reporting API (i.e. `Rails.error.handle`, etc.)
#
class LoggerErrorSubscriber
  LOG_METHODS = { info: :info, warning: :warn, error: :error }.freeze

  def report(error, handled:, severity:, source:, **)
    Rails.logger.public_send(
      LOG_METHODS.fetch(severity, :error),
      [
        'event=rails_error_reported',
        "source=#{source}",
        "handled=#{handled}",
        "error_class=#{error.class}",
        "message=#{error.message}",
        "first_frame=#{error.backtrace&.first}",
      ].join(',')
    )
  rescue StandardError => e
    Rails.logger.error("event=rails_error_subscriber_failure|#{e.class}: #{e.message}")
  end
end
