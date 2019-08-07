class MovementsOnDateJob < ApplicationJob
  queue_as :default

  def perform(date_string)
    yesterday = Date.parse(date_string) - 1.day

    movements = MovementService.movements_on(
      yesterday,
      type_filters: [
        Nomis::Models::MovementType::ADMISSION,
        Nomis::Models::MovementType::RELEASE
      ]
    )

    # Ensure that 1 movement failure doesn't prevent all the others from running
    # If we were to catch the exception here, then Sentry wouldn't report it :-(
    movements.each { |movement|
      MovementJob.perform_later(movement.to_json)
    }
  end
end
