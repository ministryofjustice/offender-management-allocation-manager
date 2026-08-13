class OmicEligibility < ApplicationRecord
  self.primary_key = :nomis_offender_id

  scope :eligible, -> { where(eligible: true) }
  scope :stale, -> { where('missing_runs_count > 0') }
end
