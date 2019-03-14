class Allocation < ApplicationRecord
  belongs_to :pom_detail

  validates :nomis_offender_id,
    :nomis_staff_id,
    :nomis_booking_id,
    :prison,
    :allocated_at_tier,
    :responsibility,
    :created_by, presence: true
end
