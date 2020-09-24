class MovementJob < ApplicationJob
  queue_as :default

  def perform(movement_json)
    movement = HmppsApi::Movement.new(JSON.parse(movement_json))
    MovementService.process_movement(movement)
  end
end
