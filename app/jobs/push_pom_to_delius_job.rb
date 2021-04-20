# frozen_string_literal: true

class PushPomToDeliusJob < ApplicationJob
  queue_as :default

  # Not much point retrying a 404 error
  discard_on Faraday::ResourceNotFound

  def perform(allocation)
    if allocation.primary_pom_nomis_id.nil?
      HmppsApi::CommunityApi.unset_pom(allocation.nomis_offender_id)

    else

      # The allocation model has formatted pom names ‘firstname, surname’ that PrisonOffenderManagerService
      # splits up to allow them to be pushed separately.
      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(allocation.primary_pom_nomis_id)

      HmppsApi::CommunityApi.set_pom(
        offender_no: allocation.nomis_offender_id,
        prison: allocation.prison,
        forename: staff.first_name,
        surname: staff.last_name
      )
    end
  end
end
