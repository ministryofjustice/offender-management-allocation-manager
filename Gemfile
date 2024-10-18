source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: '.ruby-version'

gem 'rails', '~> 7.1.3'
gem 'auto_strip_attributes'
# Need AWS SNS SDK for publishing events to HMPPS_DOMAIN_EVENTS
gem 'aws-sdk-sns'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '~> 5.0'
gem 'date_validator'
gem 'faraday', '~> 1.10.3'
gem 'net-http' # needed to undo a conflict with system libs
gem 'govuk_notify_rails', '~> 3.0.0'
gem 'govuk_design_system_formbuilder', '~> 5.4.1'
gem 'json-schema', '~> 4.0'
gem 'jsonb_accessor'
gem 'jwt'
gem 'lograge'
gem 'logstash-event'
# to enable custom log stats by writing logs directly
gem 'logstash-logger'
gem 'omniauth-oauth2'
gem 'omniauth', '~> 1.9.2', require: nil
gem 'paper_trail', '~> 15.1.0'
gem 'pg'
gem 'puma', '~> 6.4.2'
gem 'prometheus_exporter'
gem 'sidekiq', '~> 7.2.4'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sentry-sidekiq'
gem 'turbolinks', '~> 5'
gem 'terser' # javascript compressor
gem 'typhoeus'
gem 'redis'
gem 'fast_underscore', require: false
gem 'rubyzip', '< 3'
gem 'turnout'
gem 'kaminari' # pagination
gem 'prawn-rails'
gem 'rswag-api' # api-documentation
gem 'rswag-ui'  # api-documentation interface
gem 'sassc-rails'
# simple validation of email addresses.
# ministryofjustice/email_address_validation thinks Faker emails don't parse which is annoying,
# whilst also allowing invalid emails through.
# https://stackoverflow.com/questions/38611405/email-validation-in-ruby-on-rails
gem 'valid_email2'
gem 'wicked'
gem 'rails-i18n'
gem 'business_time'
gem 'matrix' # App does not use it directly but it has to be explicitly declared otherwise build breaks
gem 'shoryuken', '~> 6.0'
gem 'aws-sdk-sqs', '~> 1.55'

# Microsoft Application Insights
gem 'application_insights'

# these default gems will be removed in ruby 3.4
gem 'drb'
gem 'mutex_m'

gem 'activeadmin'

group :development, :test do
  gem 'brakeman', '~> 6.0'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'parallel_tests'
  gem 'rubocop-govuk', '~> 4.12'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'spring'
  gem 'undercover'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'faker'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'ruby-prof', '>= 0.16.0', require: false
  gem 'selenium-webdriver', '4.23.0'
  gem 'shoulda-matchers'
  gem 'simplecov'
  # we can't use the branch coverage version of simplecov, (due to code climate)
  # and it seems that simplecov-lcov doesn't correctly depend on the branch coverage version of simplecov
  gem 'simplecov-lcov', '< 0.9'
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
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen'
  gem 'memory_profiler'
  gem 'parser', '~> 3.2'
  gem 'rack-mini-profiler'
  gem 'spring-watcher-listen', '~> 2.1.0'
  gem 'stackprof'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
