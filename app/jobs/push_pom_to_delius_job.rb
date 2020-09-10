# frozen_string_literal: true

class PushPomToDeliusJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    allocation = Allocation.find_by(nomis_offender_id: nomis_offender_id)

    # We can't yet 'unset' the allocated POM in nDelius
    return if allocation.nil? || allocation.primary_pom_nomis_id.nil?

    pom_firstname, pom_secondname = PrisonOffenderManagerService.get_pom_name(allocation.primary_pom_nomis_id)

    Nomis::Elite2::CommunityApi.set_pom(
      offender_no: allocation.nomis_offender_id,
      prison: allocation.prison,
      forename: pom_firstname,
      surname: pom_secondname
    )
  end
end
