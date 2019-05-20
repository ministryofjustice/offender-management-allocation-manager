require 'yaml'
threads_number = Integer(ENV['RAILS_MAX_THREADS'] || 5)
workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads threads_number, threads_number

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'production'

on_worker_boot do
  # Re-open appenders after forking the process
  SemanticLogger.reopen
end

after_worker_boot do
  require 'prometheus_exporter/instrumentation'
  PrometheusExporter::Instrumentation::Puma.start
  PrometheusExporter::Instrumentation::Process.start(type: 'web')
end
