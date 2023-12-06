# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  before_action :ensure_admin_user

  def debugging
    return unless id

    prisoner = OffenderService.get_offender(id, ignore_legal_status: true)

    if prisoner.present?
      @offender = prisoner
      @oasys_assessment = HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(@offender.offender_no)

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
