# frozen_string_literal: true

class DebuggingController < PrisonsApplicationController
  before_action :ensure_admin_user
  before_action :set_nomis_id
  before_action :ensure_known_offender, if: -> { @nomis_id.present? }

  def debugging
    return unless @nomis_id
    return unless @known_offender

    @offender = OffenderService.get_offender(@nomis_id, ignore_legal_status: true)

    if @offender
      @sentences = Sentences.for(booking_id: @offender.booking_id)
    end

    @case_information = CaseInformation.find_by(nomis_offender_id: @nomis_id)
    @persisted_handover = CalculatedHandoverDate.find_by(nomis_offender_id: @nomis_id)
    @overidden_responsibility = Responsibility.find_by(nomis_offender_id: @nomis_id)
    @parole_reviews = ParoleReview.where(nomis_offender_id: @nomis_id).order(updated_at: :desc)
    @early_allocations = EarlyAllocation.where(nomis_offender_id: @nomis_id).order(created_at: :desc)
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

  def timeline
    return unless @nomis_id
    return unless @known_offender

    @log = AuditEvent.where(nomis_offender_id: @nomis_id).order(created_at: :desc)
  end

private

  def set_nomis_id
    @nomis_id = params[:offender_no]&.strip
  end

  def ensure_known_offender
    @known_offender = Offender.exists?(nomis_offender_id: @nomis_id)
  end
end
