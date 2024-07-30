# frozen_string_literal: true

# If prometheus metrics collection is not turned on, we will use
# a null client to dump all of the requests to /dev/null (figuratively)
# rather than expecting the prometheus_exporter process to be running.
if Rails.configuration.collect_prometheus_metrics
  # :nocov:
  require 'prometheus_exporter/client'
  ClientClass = PrometheusExporter::Client
  # :nocov:
else
  ClientClass = Class.new do
    # rubocop:disable Style/MissingRespondToMissing
    def method_missing(_method, *_args, &_block); end
    # rubocop:enable Style/MissingRespondToMissing
  end
end

module MetricTypes
  COUNTER = 'counter'
  GAUGE = 'gauge'
end

class MetricsService
  include Singleton

  def initialize
    @client = ClientClass.new
  end

  def increment_search_count(by: 1)
    send_value('searches', by, MetricTypes::COUNTER)
  end

private

  def send_value(name, value, type)
    @client.send_json(name: name, value: value, type: type)
  end
end
