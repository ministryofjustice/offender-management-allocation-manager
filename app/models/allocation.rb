# frozen_string_literal: true

class Allocation < ApplicationRecord
  belongs_to :pom_detail

  attr_accessor :responsibility

  validates :nomis_offender_id,
    :nomis_staff_id,
    :nomis_booking_id,
    :prison,
    :allocated_at_tier,
    :created_by, presence: true
end
