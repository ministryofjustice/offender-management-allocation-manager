class MovementJob < ApplicationJob
  queue_as :default

  def perform(mvment)
    MovementService::ProcessMovement.call(Nomis::Models::Movement.new(JSON.parse(mvment)))
  end
end
