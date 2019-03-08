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

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # config.logger = ActFluentLoggerRails::Logger.new
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger = ActFluentLoggerRails::Logger.new

  config.after_initialize do
    # POST a test Fluentd formatted message
    require 'fluent-logger'
    flog = Fluent::Logger::ConsoleLogger.open(STDOUT)
    flog.post('allocation-manager', 'startup': 1)

    if ENV['RAILS_URL'].present?
      require 'moneta'
      url = "rediss://#{ENV['RAILS_URL']}:6379/"
      APICache.store = Moneta.new(
        :Redis,
        url: url,
        password: ENV['RAILS_AUTH'],
        network_timeout: 5,
        read_timeout: 1.0,
        write_timeout: 1.0
      )
    end
  end
end
