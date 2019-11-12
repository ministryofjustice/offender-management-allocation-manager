# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

unless Rails.env.test?
  require 'prometheus/middleware/collector'
  require 'prometheus/middleware/exporter'

  use Rack::Deflater, if: lambda { |*, body|
    sum = 0
    body.each do |i| sum += i.length end
    sum > 512
  }

  use Prometheus::Middleware::Collector
  use Prometheus::Middleware::Exporter
end

run Rails.application
