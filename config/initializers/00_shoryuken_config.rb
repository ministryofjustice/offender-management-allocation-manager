Shoryuken.configure_server do |_config|
  # Replace Rails logger so messages are logged wherever Shoryuken is logging
  # Note: this entire block is only run by the processor, so we don't overwrite
  #       the logger when the app is running as usual.
  Rails.logger = Shoryuken::Logging.logger

  # config.server_middleware do |chain|
  #   chain.add Shoryuken::MyMiddleware
  # end
end
