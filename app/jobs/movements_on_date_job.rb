class MovementsOnDateJob < ApplicationJob
  queue_as :default

  def perform(date_string)
    yesterday = Date.parse(date_string) - 1.day

    Rails.logger.info("[MOVEMENT] Getting movements for #{yesterday}")

    movements = MovementService.movements_on(
      yesterday,
      type_filters: [
        HmppsApi::MovementType::ADMISSION,
        HmppsApi::MovementType::RELEASE
      ]
    )

    Rails.logger.info("[MOVEMENT] Found #{movements.count} movements for #{yesterday}")

    # Ensure that 1 movement failure doesn't prevent all the others from running
    # If we were to catch the exception here, then Sentry wouldn't report it :-(
    movements.each { |movement|
      MovementJob.perform_later(movement.to_json)
    }
  end
end
