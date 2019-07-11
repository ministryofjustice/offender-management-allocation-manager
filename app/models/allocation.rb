# frozen_string_literal: true

# TODO: - remove this class, as this model is no longer being used.
class Allocation < ApplicationRecord
  attr_accessor :responsibility

  scope :active_allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids, active: true)
  }
  scope :inactive_allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids, active: false)
  }
  scope :all_primary_pom_allocations, lambda { |nomis_staff_id|
    where(primary_pom_nomis_id: nomis_staff_id)
  }
  scope :active_primary_pom_allocations, lambda { |nomis_staff_id, prison|
    where(primary_pom_nomis_id: nomis_staff_id, prison: prison, active: true)
  }
  scope :primary_pom_nomis_id, lambda { |nomis_offender_id|
    active_allocations(nomis_offender_id).first.primary_pom_nomis_id
  }

  def self.deallocate_offender(nomis_offender_id)
    active_allocations(nomis_offender_id).update_all(active: false)
  end

  def self.deallocate_primary_pom(nomis_staff_id)
    all_primary_pom_allocations(nomis_staff_id).update_all(active: false)
  end

  validates :nomis_offender_id,
            :primary_pom_nomis_id,
            :nomis_booking_id,
            :prison,
            :allocated_at_tier,
            :created_by_username, presence: true
end
