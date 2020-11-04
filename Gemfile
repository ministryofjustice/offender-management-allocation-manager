source 'https://rubygems.org'
git_source(:github) do |repo| "https://github.com/#{repo}.git" end

ruby '2.6.3'

gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '~> 5.0'
gem 'faraday'
gem 'govuk_notify_rails'
# we need the extra is_csv parameter available in 5.2 and above
gem 'notifications-ruby-client', '>= 5.2'
gem 'gov_uk_date_fields'
gem 'govuk_design_system_formbuilder'
gem 'date_validator'
gem 'jbuilder', '~> 2.10'
gem 'jwt'
gem 'lograge'
gem 'logstash-event'
# to enable custom log stats by writing logs directly
gem 'logstash-logger'
gem 'omniauth-oauth2'
gem 'paper_trail'
gem 'pg'
gem 'puma', '~> 4.3'
gem 'prometheus_exporter'
gem 'rails', '~> 6.0', '>= 6.0.3.3'
gem 'sidekiq'
gem 'sentry-raven'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'
gem 'loaf'
gem 'typhoeus'
gem 'redis'
gem 'fast_underscore', require: false
gem 'flipflop'
gem 'hashdiff', ['>= 1.0.0.beta1', '< 2.0.0']
gem 'rubyzip'
gem 'turnout'
gem 'zendesk_api'
gem 'kaminari' # pagination
gem 'prawn-rails'
gem 'rswag-api' # api-documentation
gem 'rswag-ui'  # api-documentation interface
gem 'sassc-rails'
gem 'activeadmin'

group :development, :test do
  gem 'brakeman'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'parallel_tests'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-govuk'
  # needed to support Rails 6.0
  gem 'rspec-rails', '~> 4.0.0.beta2'
  gem 'rswag-specs'
  gem 'spring'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'faker'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'ruby-prof', '>= 0.16.0', require: false
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov'
  # we can't use the branch coverage version of simplecov, (due to code climate)
  # and it seems that simplecov-lcov doesn't correctly depend on the branch coverage version of simplecov
  gem 'simplecov-lcov', '< 0.8'
  # https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests
  gem 'test-prof'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'flamegraph'
  gem 'listen', '>= 3.0.5', '< 3.3'
  gem 'memory_profiler'
  # prevent warnings from parser as we are using ruby 2.6.3
  # change this when upgrading ruby version
  gem 'parser', '< 2.6.4'
  gem 'rack-mini-profiler'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'stackprof'
  gem 'undercover'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
