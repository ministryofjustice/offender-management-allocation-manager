# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  def debugging
    nomis_offender_id = id

    @offender = offender(nomis_offender_id)
    if @offender.present?
      @offender = OffenderPresenter.new(@offender, nil)
      @allocation = AllocationVersion.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        Nomis::Elite2::MovementApi.movements_for(@offender.offender_no).last
    end
  end

private

  def id
    params[:offender_no]
  end

  def offender(offender_no)
    return nil if offender_no.blank?

    OffenderService.get_offender(offender_no)
  end
end
