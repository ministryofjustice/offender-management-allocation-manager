module OffenderHelper
  def digital_prison_service_profile_path(offender_id)
    URI.join(
      Rails.configuration.digital_prison_service_host,
      "/offenders/#{offender_id}/quick-look"
    ).to_s
  end

  def pom_responsibility_label(offender)
    offender.pom_responsibility
  end

  def case_owner_label(offender)
    if offender.case_owner == 'Prison'
      'Custody'
    else
      'Community'
    end
  end
end
