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
      pom_firstname, pom_secondname = PrisonOffenderManagerService.get_pom_name(allocation.primary_pom_nomis_id)

      HmppsApi::CommunityApi.set_pom(
        offender_no: allocation.nomis_offender_id,
        prison: allocation.prison,
        forename: pom_firstname,
        surname: pom_secondname
      )
    end
  end
end
