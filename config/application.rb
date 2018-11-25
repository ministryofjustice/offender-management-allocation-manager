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

    config.api_host = ENV.fetch(
      'OFFENDER_MANAGEMENT_ALLOCATION_API', 'http://localhost:8000')
    config.sentry_dsn = ENV.fetch('SENTRY_DSN', nil)
    config.nomis_oauth_url = ENV.fetch('NOMIS_OAUTH_URL', nil)
    config.nomis_oauth_authorisation = ENV.fetch('NOMIS_OAUTH_AUTHORISATION', nil)
  end
end
