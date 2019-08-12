class MovementJob < ApplicationJob
  queue_as :default

  def perform(movement)
    MovementService.process_movement(Nomis::Models::Movement.new(JSON.parse(movement)))
  end
end
