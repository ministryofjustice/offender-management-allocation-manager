# frozen_string_literal: true

class Allocation < ApplicationRecord
  has_paper_trail ignore: [:com_name]

  has_one :case_information,
          primary_key: :nomis_offender_id,
          foreign_key: :nomis_offender_id,
          inverse_of: :allocation,
          # allocation(histories) are never destroyed in the normal cycle,
          # they are kept in case offender returns to the system
          dependent: :restrict_with_exception

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
  scope :active_pom_allocations, lambda { |nomis_staff_id, prison|
    secondaries = where(secondary_pom_nomis_id: nomis_staff_id)

    where(primary_pom_nomis_id: nomis_staff_id).or(secondaries).where(prison: prison)
  }

  scope :active, lambda { |nomis_offender_ids, prison|
    where.not(
      primary_pom_nomis_id: nil
      ).where(
        nomis_offender_id: nomis_offender_ids, prison: prison
      )
  }

  validate do |av|
    if av.primary_pom_nomis_id.present? &&
      av.primary_pom_nomis_id == av.secondary_pom_nomis_id
      errors.add(:primary_pom_nomis_id,
                 'Primary POM cannot be the same as co-working POM')
    end
  end

  # find all allocations which cannot be handed over as there is no LDU email address
  def self.without_ldu_emails
    teams = Team.joins(:local_divisional_unit).nps.merge(LocalDivisionalUnit.without_email_address)
    blank_team_cases = CaseInformation.where(team: teams).or(CaseInformation.where(team: nil))
    offenders = blank_team_cases.nps.map(&:nomis_offender_id)
    Allocation.where(nomis_offender_id: offenders)
  end

  def active?
    primary_pom_nomis_id.present?
  end

  def override_reasons
    JSON.parse(self[:override_reasons]) if self[:override_reasons].present?
  end

  def deallocate_offender(movement_type)
    self.prison = prison_fix(movement_type) if prison.blank?

    self.primary_pom_nomis_id = nil
    self.primary_pom_name = nil
    self.primary_pom_allocated_at = nil
    self.secondary_pom_nomis_id = nil
    self.secondary_pom_name = nil
    self.recommended_pom_type = nil
    self.event = if movement_type == Allocation::OFFENDER_RELEASED
                   DEALLOCATE_RELEASED_OFFENDER
                 else
                   DEALLOCATE_PRIMARY_POM
                 end
    self.event_trigger = movement_type

    # This is triggered when an offender is released, and previously we
    # were setting their prison to nil to show that the current allocation
    # object for this offender meant they were unallocated.  However, we use
    # the absence of any POM ids to show the offender is allocated, and if
    # we remove the prison, we remove the ability to see where the offender
    # was released from. So now, we do not blank the prison.
    #
    # Perhaps a better event name is `OFFENDER_RELEASED`.

    save!
  end

  # note: this creates an allocation where the co-working POM is set, but the primary
  # one is not. It should still show up in the 'waiting to allocate' bucket.
  # This appears to be safe as allocations only show up for viewing if they have
  # a non-nil primary_pom_nomis_id
  def self.deallocate_primary_pom(nomis_staff_id, prison)
    active_pom_allocations(nomis_staff_id, prison).each do |alloc|
      alloc.primary_pom_nomis_id = nil
      alloc.primary_pom_name = nil
      alloc.recommended_pom_type = nil
      alloc.primary_pom_allocated_at = nil
      alloc.event = DEALLOCATE_PRIMARY_POM
      alloc.event_trigger = USER

      alloc.save!
    end
  end

  def self.deallocate_secondary_pom(nomis_staff_id, prison)
    active_pom_allocations(nomis_staff_id, prison).each do |alloc|
      alloc.secondary_pom_nomis_id = nil
      alloc.secondary_pom_name = nil
      alloc.event = DEALLOCATE_SECONDARY_POM
      alloc.event_trigger = USER

      alloc.save!
    end
  end

  def prison_fix(movement_type)
    # In some cases we have old historical data which has no prison set
    # and this causes an issue should those offenders move or be released.
    # To handle this we will attempt to set the prison to a valid code
    # based on the event that has happened.
    if movement_type == Allocation::OFFENDER_RELEASED
      movements = Nomis::Elite2::MovementApi.movements_for(nomis_offender_id)
      if movements.present?
        movement = movements.last
        return movement.from_agency if movement.from_prison?
      end
    elsif movement_type == Allocation::OFFENDER_TRANSFERRED
      offender = OffenderService.get_offender(nomis_offender_id)
      offender.prison_id
    end
  end

  validates :nomis_offender_id,
            :nomis_booking_id,
            :allocated_at_tier,
            :event,
            :event_trigger,
            :prison, presence: true
end
