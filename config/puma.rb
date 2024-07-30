require 'yaml'

silence_single_worker_warning

threads_number = Integer(ENV['RAILS_MAX_THREADS'] || 5)
workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads threads_number, threads_number

preload_app!

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'production'

pidfile ENV.fetch('PIDFILE', '/tmp/server.pid')

# Configure Prometheus Exporter
if ENV['PROMETHEUS_METRICS']&.strip == 'on'
  after_worker_boot do
    require 'prometheus_exporter/instrumentation'
    require 'prometheus_exporter/client'

    unless PrometheusExporter::Instrumentation::Puma.started?
      PrometheusExporter::Instrumentation::Puma.start(
        labels: { type: 'puma_worker', hostname: ENV['HOSTNAME'] }
      )
    end

    PrometheusExporter::Instrumentation::Process.start(type: 'web')

    PrometheusExporter::Instrumentation::ActiveRecord.start(
      custom_labels: { type: 'puma_worker' },
      config_labels: [:database, :host]
    )
  end
end
