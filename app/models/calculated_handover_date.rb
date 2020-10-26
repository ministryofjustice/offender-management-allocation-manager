# frozen_string_literal: true

class CalculatedHandoverDate < ApplicationRecord
  # This is quite a loose relationship. It exists so that CaseInformation
  # deletes cascade and tidy up associated CalculatedHandoverDate records.
  # Ideally CalculatedHandoverDate would belong to a higher-level
  # Offender model rather than nDelius Case Information
  belongs_to :case_information,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :responsibility

  validates :nomis_offender_id, uniqueness: true, presence: true
  validates :reason, presence: true

  after_save :push_to_delius

  def self.recalculate_for(offender)
    record = self.find_or_initialize_by(nomis_offender_id: offender.offender_no)
    record.update!(
      start_date: offender.handover_start_date,
      handover_date: offender.responsibility_handover_date,
      reason: offender.handover_reason
    )
  end

private

  def push_to_delius
    # Only push if the dates have changed
    return unless saved_change_to_start_date? || saved_change_to_handover_date?

    HmppsApi::CommunityApi.set_handover_dates(
      offender_no: nomis_offender_id,
      handover_start_date: start_date,
      responsibility_handover_date: handover_date
    )
  end
end
