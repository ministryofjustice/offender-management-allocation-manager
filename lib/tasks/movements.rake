require 'rake'
require_relative '../../app//models/concerns/memory_model.rb'
require_relative '../../app/services/nomis/models/movement.rb'

namespace :movements do
  desc 'Process the movement events in the previous 24 hours'
  task process: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    # yesterday = Time.zone.today - 1.day
    yesterday = Date.iso8601('2019-02-20')

    movements = MovementService.movements_on(
      yesterday,
      type_filters: [
        Nomis::Models::MovementType::TRANSFER,
        Nomis::Models::MovementType::RELEASE
      ]
    )

    movements.each { |movement|
      MovementService.process_movement(movement)
    }
  end
end
