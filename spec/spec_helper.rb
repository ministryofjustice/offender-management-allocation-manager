require 'simplecov'

SimpleCov.minimum_coverage 100

SimpleCov.start 'rails' do
  add_filter '/gems/'
end

if ENV['CIRCLE_ARTIFACTS']
  dir = File.join(ENV['CIRCLE_ARTIFACTS'], "coverage")
  SimpleCov.coverage_dir(dir)
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

require 'vcr'
require 'active_support/testing/time_helpers'

VCR.configure do |config|
  include ActiveSupport::Testing::TimeHelpers

  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { match_requests_on: [:query] }

  config.before_playback do |interaction, cassette|
    unless %w[allocation_client_auth_header nomis_oauth_client_auth_header custodyapi_client_auth_header].include? cassette.name
      travel_to interaction.recorded_at
    end
  end

  config.filter_sensitive_data('authorisation_header') do |interaction|
    interaction.request.headers['Authorization']&.first
  end
end
