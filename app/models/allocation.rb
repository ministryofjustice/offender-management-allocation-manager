# frozen_string_literal: true

class Allocation < ApplicationRecord
  attr_accessor :responsibility

  scope :active_allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids)
  }
  scope :primary_poms, lambda { |nomis_staff_id|
    where(primary_pom_nomis_id: nomis_staff_id, active: true)
  }
  scope :secondary_poms, lambda { |nomis_staff_id|
    where(secondary_pom_nomis_id: nomis_staff_id)
  }
  scope :any_pom, lambda { |nomis_staff_id|
    where(primary_poms(nomis_staff_id)).or(secondary_poms(nomis_staff_id))
  }
  scope :primary_pom_nomis_id, lambda { |nomis_offender_id|
    active_allocations(nomis_offender_id).first.primary_pom_nomis_id
  }

  validates :nomis_offender_id,
    :primary_pom_nomis_id,
    :nomis_booking_id,
    :prison,
    :allocated_at_tier,
    :created_by_username, presence: true
end
