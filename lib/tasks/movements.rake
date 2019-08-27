# frozen_string_literal: true

require 'rake'
require_relative '../../app//models/concerns/memory_model.rb'
require_relative '../../app/services/nomis/models/movement.rb'

namespace :movements do
  desc 'Process the movement events in the previous 24 hours'
  task process: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    MovementsOnDateJob.perform_later(Time.zone.today.to_s)
  end
end
