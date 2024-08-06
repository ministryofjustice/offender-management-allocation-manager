require 'yaml'

threads_number = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_number, threads_number

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'production'

pidfile ENV.fetch('PIDFILE', '/tmp/server.pid')

# Configure Prometheus Exporter
# NOTE: if running Puma in cluster mode, the following
# instrumentation will need to be changed
#
if ENV['PROMETHEUS_METRICS']&.strip == 'on'
  on_booted do
    require 'prometheus_exporter/instrumentation'
    require 'prometheus_exporter/client'

    PrometheusExporter::Instrumentation::Process.start(type: 'web')

    PrometheusExporter::Instrumentation::Puma.start(
      labels: { type: 'puma_worker', hostname: ENV['HOSTNAME'] }
    )

    PrometheusExporter::Instrumentation::ActiveRecord.start(
      custom_labels: { type: 'puma_worker' },
      config_labels: [:database, :host]
    )
  end
end
