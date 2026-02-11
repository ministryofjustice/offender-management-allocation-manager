class OmicEligibility < ApplicationRecord
  self.primary_key = :nomis_offender_id

  scope :eligible, -> { where(eligible: true) }
end
