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
    # Don't push if the dates haven't changed
    return unless saved_change_to_start_date? || saved_change_to_handover_date?

    # Don't push if the CaseInformation record is a manual entry (meaning it didn't match against nDelius)
    # This avoids 404 Not Found errors for offenders who don't exist in nDelius (they could be Scottish, etc.)
    return if case_information.manual_entry

    HmppsApi::CommunityApi.set_handover_dates(
      offender_no: nomis_offender_id,
      handover_start_date: start_date,
      responsibility_handover_date: handover_date
    )
  end
end
