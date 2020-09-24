# frozen_string_literal: true

require 'rake'
require_relative '../../app//models/concerns/deserialisable.rb'
require_relative '../../app/models/hmpps_api/movement.rb'

namespace :movements do
  desc 'Process the movement events in the previous 24 hours'
  task process: :environment do
    MovementsOnDateJob.perform_later(Time.zone.today.to_s)
  end
end
