class Override < ApplicationRecord
  validates :nomis_staff_id, :nomis_offender_id, :override_reasons, presence: true
end
