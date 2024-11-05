# frozen_string_literal: true

# This object represents a staff member who may or my not be a POM. It is up to the caller to check
# and do something interesting if they are not a POM at a specific prison.
class StaffMember
  # maybe this method shouldn't be here?
  attr_reader :staff_id, :prison

  delegate :position, :position_description, :probation_officer?, :prison_officer?, to: :pom, allow_nil: true
  delegate :working_pattern, :status, to: :@pom_detail

  def initialize(prison, staff_id, pom_detail = nil)
    @prison = prison
    @staff_id = staff_id.to_i
    @pom_detail = pom_detail || PomDetail.find_or_create_new_active_by!(
      prison:,
      nomis_staff_id: staff_id
    )
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

  def full_name_ordered
    "#{first_name} #{last_name}"
  end

  def first_name
    staff_detail.first_name&.titleize
  end

  def last_name
    staff_detail.last_name&.titleize
  end

  def email_address
    @email_address ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi
      .fetch_email_addresses(@staff_id)
      .first
  end

  def has_pom_role?
    pom.present?
  end

  def active?
    status == 'active'
  end

  def position
    pom&.position || 'STAFF'
  end

  def pom_tasks
    allocations.map(&:pom_tasks).flatten
  end

  def allocations
    @allocations ||= allocations_summary.allocated.map do |offender|
      AllocatedOffender.new(@staff_id, allocations_summary.allocation_for(offender), offender)
    end
  end

  def unreleased_allocations
    allocations.reject(&:released?)
  end

  def has_allocation?(nomis_offender_id)
    allocations_summary.allocation_for(nomis_offender_id).present?
  end

  # Counts for ordering
  def new_allocations_count
    allocations.count(&:new_case?)
  end

  def supporting_allocations_count
    allocations.count(&:pom_supporting?)
  end

  def responsible_allocations_count
    allocations.count(&:pom_responsible?)
  end

  def coworking_allocations_count
    allocations.count(&:coworking?)
  end

  def total_allocations_count
    allocations.count
  end

private

  def allocations_summary
    @allocations_summary ||= Prison::AllocationsSummary.new(
      allocations: @prison.allocations_for_pom(@staff_id),
      offenders: @prison.allocated
    )
  end

  def pom
    @pom ||= begin
      poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(@prison.code)
      poms.find { |pom| pom.staff_id == @staff_id }
    end
  end

  def staff_detail
    @staff_detail ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(@staff_id)
  end
end
