require 'simplecov'
require 'simplecov-lcov'

# This allows both LCOV and HTML formatting -
# lcov for undercover gem and cc-test-reporter, HTML for humans
class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::LcovFormatter.new.format(result)
  end
end

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
# for cc-test-reporter after-build action
SimpleCov::Formatter::LcovFormatter.config.output_directory = 'coverage'
SimpleCov::Formatter::LcovFormatter.config.lcov_file_name = 'lcov.info'
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter

if ENV['DISABLE_COVERAGE'].blank?
  SimpleCov.start 'rails' do
    add_filter 'app/services/hmpps_api/error/'
    add_filter 'lib/allocation_validation.rb'
    add_filter 'app/jobs/custom_stats_logging_job.rb'
    add_group "Services", "app/services"

    # Set to very low minimum - now it is simply for mostly informational purposes
    minimum_coverage 20
    # sometimes coverage drops between branches - don't fail in these cases
    maximum_coverage_drop 0.5
  end
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
