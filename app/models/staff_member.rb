# frozen_string_literal: true

# This object represents a staff member who may or my not be a POM. It is up to the caller to check
# and do something interesting if they are not a POM at a specific prison.
class StaffMember
  # maybe this method shouldn't be here?
  attr_reader :staff_id, :prison

  delegate :position_description, :probation_officer?, :prison_officer?, to: :pom, allow_nil: true
  delegate :working_pattern, :status, to: :@pom_detail

  def initialize(prison, staff_id, pom_detail = default_pom_detail(prison, staff_id))
    @prison = prison
    @staff_id = staff_id.to_i
    @pom_detail = pom_detail
  end

  def full_name_ordered
    [first_name, last_name].compact_blank.join(' ')
  end
  alias_method :full_name, :full_name_ordered

  def first_name
    staff_detail.first_name&.titleize
  end

  def last_name
    staff_detail.last_name&.titleize
  end

  # rubocop:disable Rails/Delegate
  def email_address
    staff_detail.email_address
  end
  # rubocop:enable Rails/Delegate

  def has_pom_role?
    pom.present?
  end

  def active?
    status == 'active'
  end

  def position
    if pom.present?
      pom.position
    else
      'STAFF'
    end
  end

  def pom_tasks
    allocations.map(&:pom_tasks).flatten
  end

  def allocations
    @allocations ||= begin
      alloc_hash = @prison.allocations_for_pom(@staff_id).index_by(&:nomis_offender_id)

      @prison.allocated.select { |a| alloc_hash.key?(a.offender_no) }.map do |offender|
        AllocatedOffender.new(@staff_id, alloc_hash.fetch(offender.offender_no), offender)
      end
    end
  end

  def unreleased_allocations
    allocations.select do |offender|
      offender.earliest_release_date.nil? || offender.earliest_release_date > Time.zone.now.to_date
    end
  end

  def has_allocation?(nomis_offender_id)
    @prison.allocations_for_pom(@staff_id).detect { |a| a.nomis_offender_id == nomis_offender_id }.present?
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

  def pom
    @pom ||= fetch_pom
  end

  def fetch_pom
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(@prison.code)
    poms.detect { |pom| pom.staff_id == @staff_id }
  end

  # Attempt to forward-populate the PomDetail table for new records
  def default_pom_detail(prison, staff_id)
    prison.pom_details.find_by(nomis_staff_id: staff_id) || prison.pom_details.create!(working_pattern: 0.0, status: 'active', nomis_staff_id: staff_id)
  end

  def staff_detail
    @staff_detail ||= HmppsApi::NomisUserRolesApi.staff_details(@staff_id)
  end
end
