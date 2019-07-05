require 'simplecov'

SimpleCov.minimum_coverage 50

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

vcr_record_mode = ENV["VCR"] ? :all : :none

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = { record: vcr_record_mode }
  config.default_cassette_options = { match_requests_on: [
    :method,
    :query,
    :path,
    :body,
    :paging_headers
  ] }

  config.register_request_matcher :paging_headers do |r1, r2|
    paging_headers = %w[Page-Limit Page-Offset]

    r1.headers.keep_if do |k, _| paging_headers.include?(k) end
    r2.headers.keep_if do |k, _| paging_headers.include?(k) end

    r1.headers == r2.headers
  end

  config.filter_sensitive_data('authorisation_header') do |interaction|
    interaction.request.headers['Authorization']&.first
  end
end
