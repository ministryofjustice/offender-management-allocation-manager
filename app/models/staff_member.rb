# frozen_string_literal: true

# This object represents a staff member who may or my not be a POM. It is up to the caller to check
# and do something interesting if they are not a POM at a specific prison.
class StaffMember
  # maybe this method shouldn't be here?
  attr_reader :staff_id
  delegate :position_description, :probation_officer?, :prison_officer?, to: :pom
  delegate :working_pattern, :status, to: :@pom_detail

  def initialize(prison, staff_id, pom_detail = default_pom_detail(staff_id))
    @prison = prison
    @staff_id = staff_id.to_i
    @pom_detail = pom_detail
  end

  def full_name
    "#{last_name}, #{first_name}"
  end

  def first_name
    staff_detail.first_name&.titleize
  end

  def last_name
    staff_detail.last_name&.titleize
  end

  def email_address
    @email_address ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(@staff_id).first
  end

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

  def agency_id
    @prison.code
  end

  def allocations
    @allocations ||= fetch_allocations
  end

  def pending_handover_offenders
    allocations.select(&:approaching_handover?)
  end

  def tier_a
    allocations.count { |a| a.tier == 'A' }
  end

  def tier_b
    allocations.count { |a| a.tier == 'B' }
  end

  def tier_c
    allocations.count { |a| a.tier == 'C' }
  end

  def tier_d
    allocations.count { |a| a.tier == 'D' }
  end

  def no_tier
    allocations.count { |a| a.tier == 'N/A' }
  end

private

  def pom
    @pom ||= fetch_pom
  end

  def fetch_pom
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(@prison.code)
    poms.detect { |pom| pom.staff_id == @staff_id }
  end

  def fetch_allocations
    offender_hash = @prison.offenders.index_by(&:offender_no)
    allocations = Allocation.
        where(nomis_offender_id: offender_hash.keys).
        active_pom_allocations(@staff_id, @prison.code)
    allocations.map { |alloc|
      AllocatedOffender.new(@staff_id, alloc, offender_hash.fetch(alloc.nomis_offender_id))
    }
  end

  def default_pom_detail(staff_id)
    @pom_detail = PomDetail.find_or_create_by!(nomis_staff_id: staff_id) { |pom|
      pom.working_pattern = 0.0
      pom.status = 'active'
    }
  end

  def staff_detail
    @staff_detail ||= HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(@staff_id)
  end
end
