# frozen_string_literal: true

module CaseloadHelper
  def prisoner_location(offender)
    cell = offender.cell_location.presence || 'N/A'

    offender.latest_temp_movement_date.blank? ? cell : "Temporary absence (out #{format_date(offender.latest_temp_movement_date)})"
  end
end
