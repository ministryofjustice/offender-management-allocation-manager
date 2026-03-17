source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.0'

# Need AWS S3 SDK for processing PPUD exports
gem 'aws-sdk-s3'
# Need AWS SNS SDK for publishing events
gem 'aws-sdk-sns'
# Need Shoryuken for consuming domain events (includes aws-sdk-sqs)
gem 'shoryuken', '~> 7.0'

gem 'auto_strip_attributes'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'csv'
gem 'date_validator'
gem 'faraday', '~> 1.10.3'
gem 'govuk_notify_rails', '~> 3.0.0'
gem 'govuk_design_system_formbuilder', '~> 6.0.0'
gem 'json-schema', '~> 6.2'
gem 'jwt'
gem 'kaminari' # pagination
gem 'lograge'
gem 'logstash-event'
gem 'logstash-logger'
gem 'omniauth-oauth2'
gem 'omniauth', '~> 2.1.4'
gem 'omniauth-rails_csrf_protection'
gem 'ostruct'
gem 'paper_trail', '~> 17.0'
gem 'pg'
gem 'prawn-rails'
gem 'prometheus_exporter'
gem 'puma', '~> 7.2'
gem 'redis'
gem 'rswag-api' # api-documentation
gem 'rswag-ui'  # api-documentation interface
gem 'sidekiq', '~> 7.3.10'
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'sentry-sidekiq'
gem 'turbolinks', '~> 5'
gem 'turnout'
gem 'typhoeus'

# Assets pipeline
gem 'cssbundling-rails'
gem 'sprockets-rails'
gem 'terser' # javascript compressor

# simple validation of email addresses.
# ministryofjustice/email_address_validation thinks Faker emails don't parse which is annoying,
# whilst also allowing invalid emails through.
# https://stackoverflow.com/questions/38611405/email-validation-in-ruby-on-rails
gem 'valid_email2'
gem 'wicked'
gem 'rails-i18n'
gem 'business_time'

# Microsoft Application Insights
gem 'application_insights'

# Veracode static code analysis
gem 'veracode'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen'
end

group :development, :test do
  gem 'brakeman', require: false
  gem 'debug'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rubocop-govuk'
  gem 'rspec-rails'
  gem 'rswag-specs'
  gem 'spring'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov'
  # we can't use the branch coverage version of simplecov, (due to code climate)
  # and it seems that simplecov-lcov doesn't correctly depend on the branch coverage version of simplecov
  gem 'simplecov-lcov'
  # https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests
  gem 'test-prof'
  gem 'timecop'
  gem 'webmock'
end
