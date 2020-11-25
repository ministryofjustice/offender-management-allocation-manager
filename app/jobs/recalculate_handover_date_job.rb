# frozen_string_literal: true

class RecalculateHandoverDateJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)
    return if offender.nil? || offender.sentenced? == false

    CalculatedHandoverDate.recalculate_for(offender)
  end
end
