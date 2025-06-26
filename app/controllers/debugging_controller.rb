# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  before_action :ensure_admin_user

  def debugging
    return unless id

    @nomis_id = id
    @offender = OffenderService.get_offender(@nomis_id, ignore_legal_status: true)

    if @offender
      @live_handover = OffenderHandover.new(@offender).as_calculated_handover_date
      @sentences = Sentences.for(booking_id: @offender.booking_id)
    end

    @case_information = CaseInformation.find_by(nomis_offender_id: @nomis_id)
    @persisted_handover = CalculatedHandoverDate.find_by(nomis_offender_id: @nomis_id)
    @overidden_responsibility = Responsibility.find_by(nomis_offender_id: @nomis_id)
    @parole_reviews = ParoleReview.where(nomis_offender_id: @nomis_id).order('updated_at DESC')
    @oasys_assessment = HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(@nomis_id)
    @allocation = AllocationHistory.find_by(nomis_offender_id: @nomis_id)
    @movements = HmppsApi::PrisonApi::MovementApi.movements_for(
      @nomis_id, movement_types: [
        HmppsApi::MovementType::ADMISSION,
        HmppsApi::MovementType::TRANSFER,
        HmppsApi::MovementType::RELEASE,
      ]
    ).last_movement
  end

private

  def id
    params[:offender_no].present? ? params[:offender_no].strip : params[:offender_no]
  end
end
