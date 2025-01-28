# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

  config.action_controller.perform_caching = false
  config.active_job.queue_adapter = :inline

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_controller.action_on_unpermitted_parameters = :raise

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  config.allocation_manager_host = 'http://localhost:3000'
  Rails.application.default_url_options[:host] = config.allocation_manager_host

  # It seems that the default cookie store behaves very subtly different to the cache store
  # (the cookie store implicitly serializes objects, where the cache store doesn't)
  # Since cache store is used in production, tests should really be running against the same session store
  # to replicate a production-like environment (especially important for feature tests)
  config.session_store :cache_store, key: 'manage_pom_cases_session'

  # ...which means we also need to use a proper cache store, rather than the default null store
  # To avoid leaking global state between tests, we clear this cache after every spec in rails_helper.rb
  config.cache_store = :memory_store, { size: 64.megabytes }

  # Dotenv trys to autorestore ENV when using stub_const('ENV', { ..etc.. }) but rspec already frozen the object
  # https://github.com/bkeepers/dotenv/issues/482#issuecomment-1956148520
  config.dotenv.autorestore = false
end
