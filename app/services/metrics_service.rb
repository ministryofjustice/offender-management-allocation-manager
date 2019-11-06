# frozen_string_literal: true

require 'prometheus/client'
require "prometheus/client/data_stores/direct_file_store"
require 'singleton'

class MetricsService
  include Singleton

  attr_reader :search_counter, :delius_data_jobs

  def initialize
    # Set the prometheus datastore
    # We cannot use the Synchronised store because we have a pre-forking server so
    # options are disk, or SingleThreaded which is not thread safe
    Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: '/tmp/metrics')

    @prometheus = Prometheus::Client.registry

    @search_counter = @prometheus.counter(
      :search_total,
      docstring: 'A counter of searches made',
    )

    @delius_data_jobs = @prometheus.gauge(:delius_data_jobs,
      docstring: "A gauge of the number of delius data jobs",
      store_settings: { aggregation: :max }
    )
  end
end