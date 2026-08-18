class MovementsOnDateJob < ApplicationJob
  queue_as :default

  # Date-specific job; retrying days later would process stale movement data
  sidekiq_options retry: 10

  def perform(date_string)
    target_date = Date.parse(date_string)

    Rails.logger.info("[MOVEMENT] Getting movements for #{target_date}")

    movements = MovementService.movements_on(target_date, cache: false)
    movements_by_offender = movements.group_by(&:offender_no)

    Rails.logger.info(
      "[MOVEMENT] Found #{movements.count} movements for #{target_date} across #{movements_by_offender.size} offenders"
    )

    # Ensure that one offender's movement sequence failing does not prevent the
    # others from running, while still processing all ordered movements belonging
    # to the same offender
    movements_by_offender.each_value do |offender_movements|
      MovementJob.perform_later(
        offender_movements.sort_by(&:happened_at).map(&:job_payload)
      )
    end
  end
end
