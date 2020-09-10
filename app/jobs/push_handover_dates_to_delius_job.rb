# frozen_string_literal: true

class PushHandoverDatesToDeliusJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)

    # TODO: Implement 'delete' for handover dates
    return if offender.nil? || offender.handover_start_date.nil? || offender.responsibility_handover_date.nil?

    Nomis::Elite2::CommunityApi.set_handover_dates(
      offender_no: offender.offender_no,
      handover_start_date: offender.handover_start_date,
      responsibility_handover_date: offender.responsibility_handover_date
    )
  end
end
