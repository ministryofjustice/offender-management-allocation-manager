source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.0'
gem 'auto_strip_attributes'
# Need AWS SNS SDK for publishing events to HMPPS_DOMAIN_EVENTS
gem 'aws-sdk-sns'
# Need AWS S3 SDK for processing PPUD exports
gem 'aws-sdk-s3'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'coffee-rails', '~> 5.0'
# Keep version below 3.0.0 for now, as there are breaking changes
gem 'connection_pool', '< 3.0.0'
gem 'csv'
gem 'date_validator'
gem 'faraday', '~> 1.10.3'
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
gem 'paper_trail', '~> 17.0'
gem 'pg'
gem 'puma', '~> 6.6.0'
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
gem 'ostruct'
gem 'prawn-rails'
gem 'rswag-api' # api-documentation
gem 'rswag-ui'  # api-documentation interface

gem 'sassc-rails'
gem 'cssbundling-rails'

# simple validation of email addresses.
# ministryofjustice/email_address_validation thinks Faker emails don't parse which is annoying,
# whilst also allowing invalid emails through.
# https://stackoverflow.com/questions/38611405/email-validation-in-ruby-on-rails
gem 'valid_email2'
gem 'wicked'
gem 'rails-i18n'
gem 'business_time'
gem 'shoryuken', '~> 6.0'
gem 'aws-sdk-sqs', '~> 1.55'

# Microsoft Application Insights
gem 'application_insights'

# Veracode static code analysis
gem 'veracode'

group :development, :test do
  gem 'brakeman', '~> 6.0'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'parallel_tests'
  gem 'rubocop-govuk'
  gem 'rspec-rails'
  gem 'rspec-core'
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
  gem 'selenium-webdriver', '~> 4.37'
  gem 'shoulda-matchers'
  gem 'simplecov'
  # we can't use the branch coverage version of simplecov, (due to code climate)
  # and it seems that simplecov-lcov doesn't correctly depend on the branch coverage version of simplecov
  gem 'simplecov-lcov', '< 0.9'
  # https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests
  gem 'test-prof'
  gem 'timecop'
  gem 'webmock'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'listen'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'spring-watcher-listen', '~> 2.1.0'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
