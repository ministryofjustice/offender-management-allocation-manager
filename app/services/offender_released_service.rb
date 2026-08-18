# frozen_string_literal: true

# Centralises the cleanup performed when an offender leaves the service,
# whether that is a release, immigration transfer, or reconciliation.
#
# This was extracted from MovementService so the same logic can be reused
# by ReconcileReleasedOffendersService (and any future callers).
#
class OffenderReleasedService
  STINT_DATA_MODELS = [
    CaseInformation,
    CalculatedHandoverDate,
    HandoverProgressChecklist,
    Responsibility,
    OmicEligibility,
  ].freeze

  def self.release_offender(nomis_offender_id, prison_code: nil)
    unless local_release_state_present?(nomis_offender_id)
      Rails.logger.info("[RELEASE] Skipping #{nomis_offender_id}; no local release state remains")
      return
    end

    Rails.logger.info("[RELEASE] Processing release for #{nomis_offender_id}")

    deallocate(nomis_offender_id)
    destroy_stint_data(nomis_offender_id)
    inactivate_complexity(nomis_offender_id, prison_code) if prison_code.present?
  end

  def self.deallocate(nomis_offender_id)
    alloc = AllocationHistory.active.find_by(nomis_offender_id:)
    alloc.deallocate_offender_after_release if alloc
  end

  def self.destroy_stint_data(nomis_offender_id)
    STINT_DATA_MODELS.each do |model|
      model.find_by(nomis_offender_id:)&.destroy!
    rescue StandardError => e
      Rails.logger.error("[RELEASE] Failed to destroy #{model} for #{nomis_offender_id}: #{e.class} - #{e.message}")
    end
  end

  def self.inactivate_complexity(nomis_offender_id, prison_code)
    HmppsApi::ComplexityApi.inactivate(nomis_offender_id) if PrisonService.womens_prison?(prison_code)
  end

  def self.local_release_state_present?(nomis_offender_id)
    AllocationHistory.active.exists?(nomis_offender_id:) ||
      STINT_DATA_MODELS.any? { it.exists?(nomis_offender_id:) }
  end

  private_class_method :deallocate, :inactivate_complexity, :local_release_state_present?
end
