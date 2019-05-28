# frozen_string_literal: true

namespace :integration_tests do
  desc 'Clean up allocations created by staging integration tests'
  task clean_up: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    Rails.logger.info 'Deleting integration test data'

    AllocationVersion.where(created_by_username: 'MOIC_INTEGRATION_TESTS').destroy_all
  end
end
