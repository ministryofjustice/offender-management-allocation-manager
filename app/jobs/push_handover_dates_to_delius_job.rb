# frozen_string_literal: true

class PushHandoverDatesToDeliusJob < ApplicationJob
  queue_as :default

  def perform record
    HmppsApi::CommunityApi.set_handover_dates(
      offender_no: record.nomis_offender_id,
      handover_start_date: record.start_date,
      responsibility_handover_date: record.handover_date
    )
  end
end
