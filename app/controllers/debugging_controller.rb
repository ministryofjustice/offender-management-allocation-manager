# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController

  def debugging
    nomis_offender_id = id

    @offender = offender(nomis_offender_id)
    unless @offender.blank?
      @allocation = AllocationVersion.where(nomis_offender_id: @offender.offender_no)
      @movements = Nomis::Elite2::MovementApi.movements_for(@offender.offender_no).first
    end
  end

  private

  def id
    params[:offender_no]
  end

  def offender(offender_no)
    return [] if offender_no.blank?
    OffenderService.get_offender(offender_no)
  end
end