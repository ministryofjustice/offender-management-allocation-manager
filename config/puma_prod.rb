require 'yaml'
threads_number = Integer(ENV['RAILS_MAX_THREADS'] || 5)
workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads threads_number, threads_number

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'production'
