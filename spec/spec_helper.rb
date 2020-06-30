require 'simplecov'

SimpleCov.start 'rails' do
  add_filter 'app/services/nomis/error/'
  add_filter 'lib/allocation_validation.rb'
  add_filter 'app/jobs/custom_stats_logging_job.rb'
  add_filter 'app/admin/'
  add_group "Services", "app/services"

  # Try to set this to current coverage levels so that it never goes down after a PR
  # 22 lines uncovered at 99.31% coverage
  minimum_coverage 99.33
  # sometimes coverage drops between branches - don't fail in these cases
  maximum_coverage_drop 0.1
end

if ENV['CIRCLE_ARTIFACTS']
  dir = File.join(ENV['CIRCLE_ARTIFACTS'], "coverage")
  SimpleCov.coverage_dir(dir)
end

# patch to support SAMPLE=nn to only run nn tests
require "test_prof/recipes/rspec/sample"

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

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  # weirdly this assignment is implemented as a merge in VCR, so it only
  # overwrites the specified configuration options
  config.default_cassette_options = {
    # the default in :once, which seems to mess-up our cassette re-use
    record: :new_episodes,
    match_requests_on: [
      :method,
      :uri,
      :body,
      :paging_headers
    ]
  }

  config.register_request_matcher :paging_headers do |r1, r2|
    paging_headers = %w[Page-Limit Page-Offset]

    r1_headers = r1.headers.select { |k, _| paging_headers.include?(k) }
    r2_headers = r2.headers.select { |k, _| paging_headers.include?(k) }

    r1_headers == r2_headers
  end

  config.filter_sensitive_data('authorisation_header') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  config.ignore_request do |request|
    # don't record auth requests as they clutter the recordings
    request.uri =~ /__identify__|session|auth/
  end
end
