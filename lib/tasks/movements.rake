# frozen_string_literal: true

require 'rake'

namespace :movements do
  desc 'Process the movement events in the previous 24 hours'
  task process: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    MovementsOnDateJob.perform_now(Time.zone.today.to_s)
  end
end
