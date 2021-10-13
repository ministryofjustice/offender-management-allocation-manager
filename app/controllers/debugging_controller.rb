# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  before_action :ensure_admin_user

  def debugging
    nomis_offender_id = id

    prisoner = OffenderService.get_offender(nomis_offender_id) if nomis_offender_id.present?

    if prisoner.present?
      @offender = prisoner

      @allocation = AllocationHistory.find_by(nomis_offender_id: @offender.offender_no)
      @movements =
        HmppsApi::PrisonApi::MovementApi.movements_for(@offender.offender_no, %w[ADM TRN REL]).last_movement
    end
  end

private

  def id
    params[:offender_no].present? ? params[:offender_no].strip : params[:offender_no]
  end
end
