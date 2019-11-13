if Rails.env.production?
  Sidekiq.configure_server do |config|
    config.on :startup do
      require 'prometheus_exporter/instrumentation'
      PrometheusExporter::Instrumentation::Process.start type: 'sidekiq'
    end

    at_exit do
      PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
    end

    config.server_middleware do |chain|
      require 'prometheus_exporter/instrumentation'
      chain.add PrometheusExporter::Instrumentation::Sidekiq
    end

    config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler

    config.redis = {
      url: "rediss://#{Rails.configuration.redis_url}:6379",
      network_timeout: 5,
      password: Rails.configuration.redis_auth,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: "rediss://#{Rails.configuration.redis_url}:6379",
      network_timeout: 5,
      password: Rails.configuration.redis_auth,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end
end
