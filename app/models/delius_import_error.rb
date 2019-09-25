# frozen_string_literal: true

class DeliusImportError < ApplicationRecord
  DUPLICATE_NOMIS_ID = 0
  INVALID_TIER = 1
  INVALID_CASE_ALLOCATION = 2
  MISSING_DELIUS_RECORD = 3
  MISSING_TEAM = 4
  MISSING_LDU = 5
  MISMATCHED_DOB = 6

  validates :nomis_offender_id, presence: true

  validates :error_type, inclusion: {
    allow_nil: false,
    in: [DUPLICATE_NOMIS_ID, INVALID_TIER, INVALID_CASE_ALLOCATION,
         MISSING_TEAM, MISSING_LDU, MISMATCHED_DOB]
  }
end
