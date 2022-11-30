# frozen_string_literal: true

module CaseloadHelper
  def prisoner_location(offender, location_only: false)
    location = offender.location.presence || (offender.restricted_patient? ? 'Unknown' : 'N/A')

    if offender.restricted_patient?
      return location_only ? location : "This person is being held<br />under the Mental Health Act<br />at #{location}".html_safe
    end

    offender.latest_temp_movement_date.blank? ? location : "Temporary absence<br />(out #{format_date(offender.latest_temp_movement_date)})".html_safe
  end
end
