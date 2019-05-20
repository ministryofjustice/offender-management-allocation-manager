Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.log_level = :info
  config.log_tags = [:request_id]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  config.notify_api_key = ENV['LIVE_NOTIFY_API_KEY']

  # Semantic logger -> Elasticsearch
  # If there is an elastic_search available, this block will make sure that we stop
  # logging to disk, and instead log solely to elastic.
  if config.elastic_url.present?
    config.log_level = :info

    config.rails_semantic_logger.rendered = false
    config.rails_semantic_logger.quiet_assets = true
    config.rails_semantic_logger.add_file_appender = false

    config.semantic_logger.add_appender(
      appender: :elasticsearch,
      index: "offender-management-allocation-#{Rails.env}",
      url: config.elastic_url
    )
  end

  # Semantic logger -> Stdout
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.semantic_logger.add_appender(
      io: STDOUT,
      level: config.log_level,
      formatter: config.rails_semantic_logger.format
    )
  end


  if Rails.configuration.redis_url.present?
    config.cache_store = :redis_cache_store, {
      url: "rediss://#{config.redis_url}:6379/0",
      password: config.redis_auth,
      network_timeout: 5,
      read_timeout: 1.0,
      write_timeout: 1.0,

      error_handler: lambda { |method:, returning:, exception:|
                       # Report errors to Sentry as warnings
                       Raven.capture_exception exception, level: 'warning',
                                                          tags: {
                                                            method: method,
                                                            returning: returning
                                                          }
                     }
    }
  end
end
