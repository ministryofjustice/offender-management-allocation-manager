Rails.application.configure do
  config.lograge.logger = ActiveSupport::Logger.new($stdout)
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Reduce noise in the logs by ignoring the healthcheck actions
  config.lograge.ignore_actions = %w[
    HealthController#index
    HealthController#ping
  ]

  config.lograge.custom_options = lambda do |event|
    context = { request_id: event.payload[:request_id] }
    ex = event.payload[:exception_object]
    if ex
      context.merge(
        exception: event.payload[:exception],
        backtrace: event.payload[:exception_object].backtrace,
      )
    else
      context
    end
  end
end

# Disable logging from typhoeus (ETHON) because it's too noisy.
Ethon.logger = Logger.new(nil)
