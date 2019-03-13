Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.log_level = :debug
  config.log_tags = [:request_id]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  # TODO: Add live notify API key once our account goes live
  config.notify_api_key = ENV['DEV_NOTIFY_API_KEY']

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.logger = ActiveSupport::Logger.new(STDOUT)

  config.after_initialize do
    if Rails.configuration.redis_url.present?
      require 'moneta'
      url = "rediss://#{Rails.configuration.redis_url}:6379/"
      APICache.store = Moneta.new(
        :Redis,
        url: url,
        password: Rails.configuration.redis_auth,
        network_timeout: 5,
        read_timeout: 1.0,
        write_timeout: 1.0
      )
    end
  end
end
