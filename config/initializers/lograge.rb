Rails.application.configure do
  stdout_logger = ActiveSupport::Logger.new($stdout)
  config.lograge.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
  config.lograge.custom_options = lambda do |event|
    ex = event.payload[:exception_object]
    if ex
      {
        exception: event.payload[:exception],
        backtrace: event.payload[:exception_object].backtrace,
      }
    else
      {}
    end
  end
end

# Disable logging from typhoeus (ETHON) because it's too noisy.
Ethon.logger = Logger.new(nil)
