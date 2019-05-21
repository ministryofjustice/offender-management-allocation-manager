# frozen_string_literal: true

require 'rake'
require_relative '../../app/services/date_migrater.rb'

namespace :date_migrater do
  desc "Migrates Allocation 'created_at' values to
corresponding AllocationVersion records"
  task run: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    DateMigrater.run
  end
end
