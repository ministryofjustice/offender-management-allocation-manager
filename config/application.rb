require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module OffenderManagementAllocationClient
  class Application < Rails::Application
    config.load_defaults 5.2
    config.generators.system_tests = nil

    config.allocation_api_host = ENV.fetch(
      'OFFENDER_MANAGEMENT_ALLOCATION_API',
      'http://localhost:8000'
    )
    config.sentry_dsn = ENV.fetch('SENTRY_DSN', nil)
    config.nomis_oauth_host = ENV['NOMIS_OAUTH_HOST']
    config.nomis_oauth_client_id = ENV['NOMIS_OAUTH_CLIENT_ID']
    config.nomis_oauth_client_secret = ENV['NOMIS_OAUTH_CLIENT_SECRET']
    config.nomis_oauth_authorisation = ENV['NOMIS_OAUTH_AUTHORISATION']
    config.nomis_oauth_public_key = ENV['NOMIS_OAUTH_PUBLIC_KEY']
  end
end
