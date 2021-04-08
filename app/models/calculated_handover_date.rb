# frozen_string_literal: true

class CalculatedHandoverDate < ApplicationRecord
  # This is quite a loose relationship. It exists so that CaseInformation
  # deletes cascade and tidy up associated CalculatedHandoverDate records.
  # Ideally CalculatedHandoverDate would belong to a higher-level
  # Offender model rather than nDelius Case Information
  belongs_to :case_information,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :calculated_handover_date

  validates :nomis_offender_id, uniqueness: true, presence: true
  validates :reason, presence: true
end
