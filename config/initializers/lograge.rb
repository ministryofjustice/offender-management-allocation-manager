Rails.application.configure do
  stdout_logger = ActiveSupport::Logger.new($stdout)
  config.lograge.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
end

# Disable logging from typhoeus (ETHON) because it's too noisy.
Ethon.logger = Logger.new(nil)
