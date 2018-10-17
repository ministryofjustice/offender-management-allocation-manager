Rails.application.configure do
  stdout_logger = ActiveSupport::Logger.new(STDOUT)
  config.lograge.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
end
