require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OffenderManagementAllocationClient
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.active_job.queue_adapter = if ENV['RUN_JOBS_INLINE'].present?
                                        :inline
                                      else
                                        :sidekiq
                                      end

    config.allocation_manager_host = ENV.fetch('ALLOCATION_MANAGER_HOST', 'http://localhost:3000')
    Rails.application.routes.default_url_options[:host] =
      if ENV['HEROKU_APP_NAME'].present?
        "#{ENV.fetch('HEROKU_APP_NAME')}.herokuapp.com"
      else
        ENV.fetch('ALLOCATION_MANAGER_HOST', 'http://localhost:3000')
      end

    # Sentry environment set with SENTRY_CURRENT_ENV
    config.sentry_dsn = ENV['SENTRY_DSN']&.strip

    config.env_name = ENV.fetch('ENV_NAME', 'dev')&.strip

    config.keyworker_api_host = ENV['KEYWORKER_API_HOST']&.strip
    config.digital_prison_service_host = ENV['DIGITAL_PRISON_SERVICE_HOST']&.strip
    config.nomis_oauth_host = ENV['NOMIS_OAUTH_HOST']&.strip
    config.prison_api_host = ENV['PRISON_API_HOST']&.strip
    config.prisoner_search_host = ENV['PRISONER_SEARCH_HOST']&.strip
    config.complexity_api_host = ENV['COMPLEXITY_API_HOST']&.strip
    config.assess_risks_and_needs_api_host = ENV['ASSESS_RISKS_AND_NEEDS_API_HOST']&.strip
    config.manage_pom_cases_and_delius_host = ENV['MANAGE_POM_CASES_AND_DELIUS_HOST']&.strip
    config.tiering_api_host = ENV['TIERING_API_HOST']&.strip
    config.dps_frontend_components_api_host = ENV['DPS_FRONTEND_COMPONENTS_API_HOST']&.strip
    config.community_api_host = ENV['COMMUNITY_API_HOST']&.strip

    config.hmpps_oauth_client_id = ENV['HMPPS_OAUTH_CLIENT_ID']&.strip
    config.hmpps_oauth_client_secret = ENV['HMPPS_OAUTH_CLIENT_SECRET']&.strip
    config.hmpps_api_client_id = ENV['HMPPS_API_CLIENT_ID']&.strip
    config.hmpps_api_client_secret = ENV['HMPPS_API_CLIENT_SECRET']&.strip

    config.collect_prometheus_metrics = ENV['PROMETHEUS_METRICS']&.strip == 'on'
    config.support_email = ENV['SUPPORT_EMAIL']&.strip
    config.redis_url = ENV['REDIS_URL']&.strip
    config.redis_auth = ENV['REDIS_AUTH']&.strip
    config.connection_pool_size = ENV['RAILS_WEB_CONCURRENCY']&.strip || 5

    config.cache_expiry = (ENV['CACHE_TIMEOUT']&.strip || 60.minutes).to_i

    config.time_zone = 'London'

    # overriding the normal wrapping in a div with class 'field-with-errors' seems to be
    # neccesary in this project, otherwise Gov Design system check-boxes and radio buttons
    # don't 'check' visibly to the user even though they pass all the tests.
    config.action_view.field_error_proc = proc { |html_tag, _instance|
      html_tag
    }

    config.active_record.schema_format = :sql

    config.gtm_id = ENV['GTM_ID']&.strip

    config.active_record.yaml_column_permitted_classes = [
      Symbol,
      ActiveSupport::HashWithIndifferentAccess,
      Time,
      Date,
    ]

    config.action_mailer.observers = %w[MailPublishAuditEventObserver]

    config.domain_event_handlers = {
      # event_type               => handler class (as a string)
      'offender-management.noop' => 'DomainEvents::Handlers::NoopHandler',
      'prisoner-offender-search.prisoner.updated' => 'DomainEvents::Handlers::PrisonerUpdatedHandler',
      'probation-case.registration.added' => 'DomainEvents::Handlers::ProbationChangeHandler',
      'probation-case.registration.deleted' => 'DomainEvents::Handlers::ProbationChangeHandler',
      'probation-case.registration.deregistered' => 'DomainEvents::Handlers::ProbationChangeHandler',
      'probation-case.registration.updated' => 'DomainEvents::Handlers::ProbationChangeHandler',
      'tier.calculation.complete' => 'DomainEvents::Handlers::TierChangeHandler',
      'OFFENDER_MANAGER_CHANGED' => 'DomainEvents::Handlers::ProbationChangeHandler',
    }
  end
end
