# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'
require 'support/helpers/api_helper'
require 'support/helpers/jwt_helper'
require 'support/helpers/features_helper'
require 'support/helpers/auth_helper'
require 'support/helpers/api_helper'
require 'capybara/rspec'
require 'webmock/rspec'
require 'paper_trail/frameworks/rspec'

Capybara.default_max_wait_time = 4
Capybara.asset_host = 'http://localhost:3000'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

OmniAuth.config.test_mode = true

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.use_transactional_fixtures = false
  config.example_status_persistence_file_path = 'tmp/example_status.txt'
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, :js) do
    page.driver.browser.manage.window.resize_to(1280,3072)
  end
  
  config.before(:each, :raven_intercept_exception) do
    Rails.configuration.sentry_dsn = 'https://test.com'
    allow(Raven).to receive(:capture_exception)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include ActiveSupport::Testing::TimeHelpers
  config.include JWTHelper
  config.include FeaturesHelper
  config.include AuthHelper
  config.include ApiHelper

  config.after(:each, :raven_intercept_exception) do
    Rails.configuration.sentry_dsn = nil
  end

  config.around(:each, :queueing) do |example|
    ActiveJob::Base.queue_adapter.tap do |adapter|
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = adapter
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
