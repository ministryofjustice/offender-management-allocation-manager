module OffenderHelper
  def digital_prison_service_profile_path(offender_id)
    Rails.configuration.digital_prison_service_host +
        "/offenders/#{offender_id}/quick-look"
  end
end
