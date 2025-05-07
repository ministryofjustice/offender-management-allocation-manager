# frozen_string_literal: true

class AllocationHistory < ApplicationRecord
  self.table_name = 'allocation_history'

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id, optional: true

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
  MANUAL_CHANGE = 3

  after_commit :publish_allocation_changed_event

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
    offender_released: OFFENDER_RELEASED,
    manual_change: MANUAL_CHANGE
  }

  scope :active, -> { where.not(primary_pom_nomis_id: nil) }

  scope :at_prison, ->(prison) { where(prison:) }

  scope :active_pom_allocations, lambda { |nomis_staff_id, prison|
    active.for_pom(nomis_staff_id).at_prison(prison)
  }

  scope :active_allocations_for_prison, ->(prison) { active.at_prison(prison) }

  scope :for_pom, lambda { |nomis_staff_id|
    where(primary_pom_nomis_id: nomis_staff_id)
      .or(where(secondary_pom_nomis_id: nomis_staff_id))
  }

  validates :allocated_at_tier,
            :event,
            :event_trigger,
            :prison, presence: true

  validates :nomis_offender_id, presence: true, uniqueness: true

  validate do |av|
    if av.primary_pom_nomis_id.present? &&
      av.primary_pom_nomis_id == av.secondary_pom_nomis_id
      errors.add(:primary_pom_nomis_id,
                 'Primary POM cannot be the same as co-working POM')
    end
  end

  # find all allocations which cannot be handed over as there is no LDU email address
  def self.without_ldu_emails
    blank_ldu_cases = CaseInformation.where(local_delivery_unit: nil)
    offenders = blank_ldu_cases.where(enhanced_resourcing: true).pluck(:nomis_offender_id)
    AllocationHistory.where(nomis_offender_id: offenders)
  end

  def active?
    primary_pom_nomis_id.present?
  end

  def override_reasons
    JSON.parse(self[:override_reasons]) if self[:override_reasons].present?
  end

  def get_old_versions
    versions.map(&:reify).compact
  end

  def previously_allocated_poms
    get_old_versions.map { |h| [h.primary_pom_nomis_id, h.secondary_pom_nomis_id] }.flatten.compact.uniq
  end

  # NOTE: this creates an allocation where the co-working POM is set, but the primary
  # one is not. It should still show up in the 'waiting to allocate' bucket.
  # This appears to be safe as allocations only show up for viewing if they have
  # a non-nil primary_pom_nomis_id
  def self.deallocate_primary_pom(nomis_staff_id, prison)
    active_pom_allocations(nomis_staff_id, prison).each do |alloc|
      alloc.deallocate_primary_pom(event_trigger: USER)
    end
  end

  def deallocate_primary_pom(event_trigger: USER)
    self.primary_pom_nomis_id = nil
    self.primary_pom_name = nil
    self.recommended_pom_type = nil
    self.primary_pom_allocated_at = nil
    self.event = DEALLOCATE_PRIMARY_POM
    self.event_trigger = event_trigger
    save!
  end

  def self.deallocate_secondary_pom(nomis_staff_id, prison)
    active_pom_allocations(nomis_staff_id, prison).each do |alloc|
      alloc.deallocate_secondary_pom(event_trigger: USER)
    end
  end

  def deallocate_secondary_pom(event_trigger: USER)
    self.secondary_pom_nomis_id = nil
    self.secondary_pom_name = nil
    self.event = DEALLOCATE_SECONDARY_POM
    self.event_trigger = event_trigger
    save!
  end

  def deallocate_offender_after_release
    deallocate_offender(
      event: AllocationHistory::DEALLOCATE_RELEASED_OFFENDER,
      event_trigger: AllocationHistory::OFFENDER_RELEASED
    )
  end

  def deallocate_offender_after_transfer
    deallocate_offender(
      event: AllocationHistory::DEALLOCATE_PRIMARY_POM,
      event_trigger: AllocationHistory::OFFENDER_TRANSFERRED
    )
  end

  # check for changes in the last week where the target value
  # (item[1] in the array) is our staff_id
  def new_case_for?(staff_id)
    recent_versions = versions.where('created_at >= ?', 7.days.ago)
    changes = recent_versions.map { |c| YAML.unsafe_load(c.object_changes) }

    changes.any? do |change|
      (change.key?('primary_pom_nomis_id') && change['primary_pom_nomis_id'][1] == staff_id) ||
      (change.key?('secondary_pom_nomis_id') && change['secondary_pom_nomis_id'][1] == staff_id)
    end
  end

private

  def deallocate_offender(event:, event_trigger:)
    return unless active?

    primary_pom = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(primary_pom_nomis_id)

    # If the offender has been released from prison, OffenderService.get_offender will return nil (due to "OUT" being an unrecognised Prison)
    # So instead we'll call the Prison API directly to get just the Prison record of the offender. We don't need a full MpcOffender object.
    # We'll also ignore the offender's legal status, in case they're now on remand / unsentenced / now serving a civil sentence.
    # We only need the offender's name, so this is enough for us.
    offender = HmppsApi::PrisonApi::OffenderApi.get_offender(nomis_offender_id, ignore_legal_status: true)

    mail_params = {
      email: primary_pom.email_address,
      pom_name: primary_pom.first_name.titleize,
      offender_name: offender.full_name,
      nomis_offender_id: nomis_offender_id,
      prison_name: Prison.find(prison).name,
      url: Rails.application.routes.url_helpers.prison_staff_caseload_url(prison, primary_pom_nomis_id)
    }

    update!(
      event: event,
      event_trigger: event_trigger,
      primary_pom_nomis_id: nil,
      primary_pom_name: nil,
      primary_pom_allocated_at: nil,
      secondary_pom_nomis_id: nil,
      secondary_pom_name: nil,
      recommended_pom_type: nil,
    )

    if mail_params[:email].present?
      PomMailer.with(**mail_params).offender_deallocated.deliver_later
    else
      Rails.logger.error 'event=deallocate_offender_blank_email,' \
                         "nomis_offender_id=#{nomis_offender_id}," \
                         "primary_pom_nomis_id=#{primary_pom_nomis_id}," \
                         "event_trigger=#{event_trigger}|" \
                         'Attempted to schedule an email send but the primary POM email address is blank'
    end
  end

  def publish_allocation_changed_event
    return unless saved_change_to_primary_pom_nomis_id?

    DomainEvents::Event.new(
      event_type: 'allocation.changed',
      version: 1,
      description: 'A POM allocation has changed',
      detail_url: "#{Rails.configuration.allocation_manager_host}/api/allocation/#{nomis_offender_id}/primary_pom",
      noms_number: nomis_offender_id,
      additional_information: {
        'staffCode' => primary_pom_nomis_id,
        'prisonId' => prison
      }
    ).publish
  end
end
