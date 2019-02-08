class Allocation < ApplicationRecord
  belongs_to :pom_detail

  validates :nomis_offender_id, :nomis_booking_id, :prison, :allocated_at_tier,
    :created_by, presence: true
end
