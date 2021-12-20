# frozen_string_literal: true

module CaseloadHelper
  def prisoner_location(offender, location_only = false)
    location = offender.location.presence || (offender.restricted_patient? ? 'Unknown' : 'N/A')

    if offender.restricted_patient?
      return location_only ? location : "This person is being held under the Mental Health Act at #{location}"
    end

    offender.latest_temp_movement_date.blank? ? location : "Temporary absence (out #{format_date(offender.latest_temp_movement_date)})"
  end
end
