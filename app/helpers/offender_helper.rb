module OffenderHelper
  def new_nomis_profile_path(offender_id)
    "#{Rails.configuration.new_nomis_host}/offenders/#{offender_id}/quick-look"
  end
end
