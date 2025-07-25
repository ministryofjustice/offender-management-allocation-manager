# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'
require 'capybara/rspec'
require 'webmock/rspec'

Dir.glob(File.join(__dir__, 'support/**/*.rb')).each do |file|
  require file
end

Selenium::WebDriver.logger.level = :error
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 10
Capybara.asset_host = 'http://localhost:3000'
Capybara.register_driver(:rack_test) do |app|
  Capybara::RackTest::Driver.new(
    app,
    redirect_limit: 10,
  )
end

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
  config.example_status_persistence_file_path = "#{ENV.fetch('SPEC_STATUS_PATH', 'tmp/spec_status')}/#{ENV.fetch('TEST_ENV_NUMBER', 'all')}.txt"
  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each, :js) do
    page.driver.browser.manage.window.resize_to(1280,3072)
  end

  config.before(:each, :disable_push_to_delius) do
    # Stub the publishing handover.changed domain events. Useful when running ProcessDeliusDataJob, which attempts
    # to push to the Community API when it recalculates handover dates
    allow_any_instance_of(DomainEvents::Event).to receive(:publish)
  end

  config.before(:each, :disable_early_allocation_event) do
    allow(EarlyAllocationService).to receive(:send_early_allocation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean

    # Clear the Rails cache between each test to isolate tests
    # We need to use a proper cache store to support the cache-backed session store
    Rails.cache.clear
  end

  config.include ActiveSupport::Testing::TimeHelpers
  config.include FeaturesHelper
  config.include AuthHelper
  config.include ApiHelper
  config.include ScenarioSetupHelper

  config.before(:each, type: :view) do
    # This is needed for any view test that uses the sort_link and sort_arrow helpers
    # taken from https://github.com/bootstrap-ruby/rails-bootstrap-navbar/issues/15
    allow_any_instance_of(ActionController::TestRequest).to receive(:original_url).and_return('')
  end

  config.around(:each, :queueing) do |example|
    ActiveJob::Base.queue_adapter.tap do |adapter|
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = adapter
    end
  end

  WebMock.disable_net_connect!(allow_localhost: true)

  # in VCR-tagged tests, allow HTTP connections if we're in record mode,
  # but reset back to default afterward
  config.around(:each, :vcr) do |example|
    # VCR tests expect Leeds (HMP) prison to exist
    unless Prison.where(code: 'LEI').exists?
      create(:prison, code:'LEI')
    end

    if [:new_episodes, :all].include?(VCR.configuration.default_cassette_options[:record])
      WebMock.allow_net_connect!
      example.run
      WebMock.disable_net_connect!(allow_localhost: true)
    else
      example.run
    end
  end

  config.before(:each) do |example|
    stub_auth_token
    stub_request(:get, %r{#{Rails.configuration.prison_api_host}/api/offender-sentences/booking/\d+/sentenceTerms}).to_return(body: [].to_json)

    if [:feature, :controller].include?(example.metadata[:type]) and
      example.metadata[:skip_dps_header_footer_stubbing].blank?

      stub_dps_header_footer
    end

    if example.metadata[:enable_allocation_change_publish].blank?
      allow_any_instance_of(AllocationHistory).to receive(:publish_allocation_changed_event)
    end

    if example.metadata[:skip_active_caseload_check_stubbing].blank?
      if example.metadata[:type] == :controller
        allow(controller).to receive(:check_active_caseload) if controller.respond_to?(:check_active_caseload, true)
      elsif example.metadata[:type] == :feature
        stub_active_caseload_check
      end
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Set the locale for Faker gem to en-GB
# The en-GB locale gives us UK counties (used by the LocalDeliveryUnit factory)
# See all the things we gain here: https://github.com/faker-ruby/faker/blob/master/lib/locales/en-GB.yml
Faker::Config.locale = 'en-GB'

# Define a global sequence for generating NOMIS Offender IDs
# NOMIS offender IDs follow the format: <letter><4 numbers><2 letters> (all uppercase)
FactoryBot.define do
  sequence :nomis_offender_id do |seq|
    index = seq - 1 # because seq starts at 1, not 0
    number = "%04d" % (index / 26) # zero-pad to 4 digits, e.g. 0001
    letter = ('A'..'Z').to_a[index % 26]

    # Start with "T" to indicate that this is a "test" offender ID
    # In the real world, offender IDs don't begin with "T"
    "T#{number}A#{letter}"
  end
end

Shoryuken::Logging.logger = Rails.logger
