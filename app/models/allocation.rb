class Allocation < ApplicationRecord
  belongs_to :prison_offender_manager

  validates :nomis_offender_id, :nomis_booking_id, :prison, :allocated_at_tier,
    :created_by, presence: true
end
