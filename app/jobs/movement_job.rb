class MovementJob < ApplicationJob
  queue_as :default

  # Date-specific job; retrying days later would process stale movement data
  sidekiq_options retry: 10

  def perform(movement_payload_or_payloads)
    payloads = movement_payload_or_payloads.is_a?(Array) ? movement_payload_or_payloads : [movement_payload_or_payloads]

    payloads.each do |movement_payload|
      movement = HmppsApi::Movement.from_job_payload(movement_payload)
      MovementService.process_movement(movement)
    end
  end
end
