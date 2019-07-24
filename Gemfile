source 'https://rubygems.org'
git_source(:github) do |repo| "https://github.com/#{repo}.git" end

ruby '2.6.3'

gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '~> 5.0'
gem 'faraday'
gem 'govuk_notify_rails'
gem 'jbuilder', '~> 2.9'
gem 'jwt'
gem 'lograge'
gem 'logstash-event'
gem 'omniauth-oauth2'
gem 'paper_trail'
gem 'pg'
gem 'puma', '~> 4.0'
gem 'prometheus_exporter'
gem 'rails', '~> 5.2.3'
gem 'sass-rails', '~> 5.0'
gem 'sidekiq'
gem 'sentry-raven'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'loaf'
gem 'typhoeus'
gem 'redis'
gem 'plissken'
gem 'fast_underscore', require: false
gem 'flipflop'
gem 'hashdiff', ['>= 1.0.0.beta1', '< 2.0.0']

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'dotenv-rails'
  gem 'rspec-rails'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'faker'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'

  gem 'rack-mini-profiler'
  gem 'flamegraph'
  gem 'stackprof'
  gem 'memory_profiler'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
