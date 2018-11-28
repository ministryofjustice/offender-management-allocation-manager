# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'
require 'support/helpers/jwt_helper'
require 'capybara/rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
  
  config.before(:each, :expect_exception) do
    Rails.configuration.sentry_dsn = 'https://test.com'
    allow(Raven).to receive(:capture_exception)
  end

  config.include JWTHelper

   config.after(:each, :epect_exception) do
    Rails.configuration.sentry_dsn = nil
  end
end
