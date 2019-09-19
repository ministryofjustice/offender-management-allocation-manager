# frozen_string_literal: true

class AllocationVersion < ApplicationRecord
  has_paper_trail

  ALLOCATE_PRIMARY_POM = 0
  REALLOCATE_PRIMARY_POM = 1
  ALLOCATE_SECONDARY_POM = 2
  REALLOCATE_SECONDARY_POM = 3
  DEALLOCATE_PRIMARY_POM = 4
  DEALLOCATE_SECONDARY_POM = 5
  DEALLOCATE_RELEASED_OFFENDER = 6

  USER = 0
  OFFENDER_TRANSFERRED = 1
  OFFENDER_RELEASED = 2

  # When adding a new 'event' or 'event trigger'
  # make sure the constant it points to
  # has a value that is sequential and does not
  # re-assign an already existing value
  enum event: {
    allocate_primary_pom: ALLOCATE_PRIMARY_POM,
    reallocate_primary_pom: REALLOCATE_PRIMARY_POM,
    allocate_secondary_pom: ALLOCATE_SECONDARY_POM,
    reallocate_secondary_pom: REALLOCATE_SECONDARY_POM,
    deallocate_primary_pom: DEALLOCATE_PRIMARY_POM,
    deallocate_secondary_pom: DEALLOCATE_SECONDARY_POM,
    deallocate_released_offender: DEALLOCATE_RELEASED_OFFENDER
  }

  # 'Event triggers' capture the subject or action that triggered the event
  enum event_trigger: {
    user: USER,
    offender_transferred: OFFENDER_TRANSFERRED,
    offender_released: OFFENDER_RELEASED
  }

  scope :allocations, lambda { |nomis_offender_ids|
    where(nomis_offender_id: nomis_offender_ids)
  }
  scope :all_primary_pom_allocations, lambda { |nomis_staff_id|
    where(
      primary_pom_nomis_id: nomis_staff_id
    )
  }
  scope :active_pom_allocations, lambda { |nomis_staff_id, prison|
    secondaries = where(secondary_pom_nomis_id: nomis_staff_id)

    where(primary_pom_nomis_id: nomis_staff_id).or(secondaries).where(prison: prison)
  }
  scope :active_primary_pom_allocations, lambda { |nomis_staff_id, prison|
    where(
      primary_pom_nomis_id: nomis_staff_id,
      prison: prison
    )
  }

  validate do |alloc|
    if alloc.secondary_pom_nomis_id.present? && alloc.primary_pom_nomis_id.blank? &&
      errors.add("Can't have a secondary POM in an allocation without a primary POM")
    end
  end

  # Note - this only works for active allocations, not ones that have been de-allocated
  # If this returns false it means that we are a secondary/co-working allocation
  def for_primary_only?
    secondary_pom_nomis_id.blank?
  end

  validate do |av|
    if av.primary_pom_nomis_id.present? &&
      av.primary_pom_nomis_id == av.secondary_pom_nomis_id
      errors.add(:primary_pom_nomis_id,
                 'Primary POM cannot be the same as co-working POM')
    end
  end

  def active?
    primary_pom_nomis_id.present?
  end

  def override_reasons
    JSON.parse(self[:override_reasons]) if self[:override_reasons].present?
  end

  def self.deallocate_offender(nomis_offender_id, movement_type)
    alloc = AllocationVersion.find_by(
      nomis_offender_id: nomis_offender_id
    )

    return if alloc.nil?

    alloc.prison = prison_fix(alloc, movement_type) if alloc.prison.blank?

    alloc.primary_pom_nomis_id = nil
    alloc.primary_pom_name = nil
    alloc.primary_pom_allocated_at = nil
    alloc.secondary_pom_nomis_id = nil
    alloc.secondary_pom_name = nil
    alloc.recommended_pom_type = nil
    if movement_type == AllocationVersion::OFFENDER_RELEASED
      alloc.event = DEALLOCATE_RELEASED_OFFENDER
    else
      alloc.event = DEALLOCATE_PRIMARY_POM
    end
    alloc.event_trigger = movement_type

    # This is triggered when an offender is released, and previously we
    # were setting their prison to nil to show that the current allocation
    # object for this offender meant they were unallocated.  However, we use
    # the absence of any POM ids to show the offender is allocated, and if
    # we remove the prison, we remove the ability to see where the offender
    # was released from. So now, we do not blank the prison.
    #
    # Perhaps a better event name is `OFFENDER_RELEASED`.

    alloc.save!
  end

  def self.deallocate_primary_pom(nomis_staff_id)
    all_primary_pom_allocations(nomis_staff_id).each do |alloc|
      alloc.primary_pom_nomis_id = nil
      alloc.primary_pom_name = nil
      alloc.recommended_pom_type = nil
      alloc.primary_pom_allocated_at = nil
      alloc.event = DEALLOCATE_PRIMARY_POM
      alloc.event_trigger = USER

      alloc.save!
    end
  end

  def self.prison_fix(allocation, movement_type)
    # In some cases we have old historical data which has no prison set
    # and this causes an issue should those offenders move or be released.
    # To handle this we will attempt to set the prison to a valid code
    # based on the event that has happened.
    if movement_type == AllocationVersion::OFFENDER_RELEASED
      movements = Nomis::Elite2::MovementApi.movements_for(allocation.nomis_offender_id)
      if movements.present?
        movement = movements.first
        return movement.from_agency if movement.from_prison?
      end
    elsif movement_type == AllocationVersion::OFFENDER_TRANSFERRED
      offender = OffenderService.get_offender(allocation.nomis_offender_id)
      offender.latest_location_id
    end
  end

  validates :nomis_offender_id,
            :nomis_booking_id,
            :allocated_at_tier,
            :event,
            :event_trigger,
            :prison, presence: true
end
