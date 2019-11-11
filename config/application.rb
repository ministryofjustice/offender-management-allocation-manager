require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module OffenderManagementAllocationClient
  class Application < Rails::Application
    # Before filter for Flipflop dashboard. Replace with a lambda or method name
    # defined in ApplicationController to implement access control.
    config.flipflop.dashboard_access_filter = -> { :current_user_is_spo? }

    config.load_defaults 5.2
    config.exceptions_app = routes
    config.generators.system_tests = nil
    config.active_job.queue_adapter = :sidekiq
    config.allocation_manager_host = ENV.fetch(
      'ALLOCATION_MANAGER_HOST',
      'http://localhost:3000'
    )
    Rails.application.routes.default_url_options[:host] = ENV.fetch(
      'ALLOCATION_MANAGER_HOST',
      'http://localhost:3000'
    )
    config.sentry_dsn = ENV['SENTRY_DSN']&.strip
    config.keyworker_api_host = ENV['KEYWORKER_API_HOST']&.strip
    config.digital_prison_service_host = ENV['DIGITAL_PRISON_SERVICE_HOST']&.strip
    config.nomis_oauth_host = ENV['NOMIS_OAUTH_HOST']&.strip
    config.nomis_oauth_client_id = ENV['NOMIS_OAUTH_CLIENT_ID']&.strip
    config.nomis_oauth_client_secret = ENV['NOMIS_OAUTH_CLIENT_SECRET']&.strip
    config.nomis_oauth_public_key = ENV['NOMIS_OAUTH_PUBLIC_KEY']&.strip
    config.prometheus_metrics = ENV['PROMETHEUS_METRICS']&.strip
    config.ga_tracking_id = ENV['GA_TRACKING_ID']&.strip
    config.support_email = ENV['SUPPORT_EMAIL']&.strip
    config.redis_url = ENV['REDIS_URL']&.strip
    config.redis_auth = ENV['REDIS_AUTH']&.strip
    config.zendesk_token = ENV['ZENDESK_TOKEN']&.strip
    config.zendesk_password = ENV['ZENDESK_PASSWORD']&.strip
    config.zendesk_url = ENV['ZENDESK_URL']&.strip
    config.zendesk_username = ENV['ZENDESK_USERNAME']&.strip
    config.connection_pool_size = ENV['RAILS_WEB_CONCURRENCY']&.strip || 5
    config.zendesk_enabled =
      [config.zendesk_username, config.zendesk_url, config.zendesk_password].all?

    config.cache_expiry = 60.minutes

    # overriding the normal wrapping in a div with class 'field-with-errors' seems to be
    # neccesary in this project, otherwise Gov Design system check-boxes and radio buttons
    # don't 'check' visibly to the user even though they pass all the tests.
    config.action_view.field_error_proc = proc { |html_tag, _instance|
      html_tag
    }
  end
end
