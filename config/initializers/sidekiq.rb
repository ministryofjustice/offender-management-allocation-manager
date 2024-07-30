if Rails.env.production?
  Sidekiq.configure_server do |config|
    # Configure Prometheus Exporter
    if ENV['PROMETHEUS_METRICS']&.strip == 'on'
      config.on :startup do
        require 'prometheus_exporter/instrumentation'
        PrometheusExporter::Instrumentation::Process.start(
          type: 'sidekiq', labels: { hostname: ENV['HOSTNAME'] }
        )
        PrometheusExporter::Instrumentation::SidekiqProcess.start
        PrometheusExporter::Instrumentation::SidekiqQueue.start
        PrometheusExporter::Instrumentation::SidekiqStats.start
      end

      at_exit do
        PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
      end

      config.server_middleware do |chain|
        require 'prometheus_exporter/instrumentation'
        chain.add PrometheusExporter::Instrumentation::Sidekiq
      end

      config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler
    end

    config.redis = {
      url: Rails.configuration.redis_url.to_s,
      network_timeout: 5,
      read_timeout: 1.0,
      write_timeout: 1.0
    }

    # Sidekiq logger initialised and the level is set to FATAL to ensure that sensitive data isn't logged.
    config.logger.level = Logger::FATAL
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: Rails.configuration.redis_url.to_s,
      network_timeout: 5,
      read_timeout: 1.0,
      write_timeout: 1.0
    }
  end
end

if Rails.env.test?
  Sidekiq.logger.level = Logger::WARN
end
