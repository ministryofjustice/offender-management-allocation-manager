# frozen_string_literal: true

class AllocationVersion < ApplicationRecord
  has_paper_trail

  attr_accessor :responsibility

  ALLOCATE_PRIMARY_POM = 0
  REALLOCATE_PRIMARY_POM = 1
  ALLOCATE_SECONDARY_POM = 2
  REALLOCATE_SECONDARY_POM = 3
  DEALLOCATE_PRIMARY_POM = 4
  DEALLOCATE_SECONDARY_POM = 5

  USER = 0
  OFFENDER_MOVEMENT = 1

  # When adding a new 'event' or 'event trigger'
  # make sure the constant it points to
  # has a value that is sequential and does not
  # re-assign an already existing value
  enum event: {
    allocate_primary_pom: ALLOCATE_PRIMARY_POM,
    reallocate_primary_pom: REALLOCATE_PRIMARY_POM,
    allocate_secondary_pom: ALLOCATE_SECONDARY_POM,
    reallocate_seondary_pom: REALLOCATE_SECONDARY_POM,
    deallocate_primary_pom: DEALLOCATE_PRIMARY_POM,
    deallocate_secondary_pom: DEALLOCATE_SECONDARY_POM
  }

  # 'Event triggers' capture the subject or action that triggered the event
  enum event_trigger: {
    user: USER,
    offender_movement: OFFENDER_MOVEMENT
  }

  scope :allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids)
  }
  scope :all_primary_pom_allocations, lambda { |nomis_staff_id|
    where(
      primary_pom_nomis_id: nomis_staff_id,
      event: ALLOCATE_PRIMARY_POM || REALLOCATE_PRIMARY_POM
    )
  }
  scope :active_primary_pom_allocations, lambda { |nomis_staff_id, prison|
    where(
      primary_pom_nomis_id: nomis_staff_id,
      prison: prison,
      event: ALLOCATE_PRIMARY_POM || REALLOCATE_PRIMARY_POM
    )
  }
  scope :primary_pom_nomis_id, lambda { |nomis_offender_id|
    allocations(nomis_offender_id).primary_pom_nomis_id
  }
  
  def self.deallocate_offender(nomis_offender_id)
    allocations(nomis_offender_id).
      update_all(
        primary_pom_nomis_id: nil,
        primary_pom_name: nil,
        secondary_pom_nomis_id: nil,
        secondary_pom_name: nil,
        event: DEALLOCATE_PRIMARY_POM,
        event_trigger: OFFENDER_MOVEMENT
      )
  end

  def self.deallocate_primary_pom(nomis_staff_id)
    all_primary_pom_allocations(nomis_staff_id).
      update_all(
        primary_pom_nomis_id: nil,
        primary_pom_name: nil,
        event: DEALLOCATE_PRIMARY_POM,
        event_trigger: USER
      )
  end

  validates :nomis_offender_id,
            :primary_pom_nomis_id,
            :nomis_booking_id,
            :prison,
            :allocated_at_tier,
            :event,
            :event_trigger, presence: true
end
