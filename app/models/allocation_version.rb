# frozen_string_literal: true

class AllocationVersion < ApplicationRecord
  has_paper_trail

  attr_accessor :responsibility

  enum event: [
    :allocate_primary_pom,
    :reallocate_primary_pom
  ]

  enum event_trigger: [
    :user,
    :movement
  ]

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
            :event,
            :event_trigger, presence: true
end
