class Override < ApplicationRecord
  validates :nomis_staff_id, :nomis_offender_id, :override_reason, presence: true
end
