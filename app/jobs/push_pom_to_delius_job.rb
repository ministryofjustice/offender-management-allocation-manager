# frozen_string_literal: true

class PushPomToDeliusJob < ApplicationJob
  queue_as :default

  def perform(allocation)
    # We can't yet 'unset' the allocated POM in nDelius
    if allocation.primary_pom_nomis_id.nil?
      HmppsApi::CommunityApi.unset_pom(allocation.nomis_offender_id)

    else

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
